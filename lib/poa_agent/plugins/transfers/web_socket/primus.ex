defmodule POAAgent.Plugins.Transfers.WebSocket.Primus do
  use POAAgent.Plugins.Transfer

  alias POAAgent.Entity

  alias POAAgent.Entity.Host
  alias POAAgent.Entity.Ethereum

  alias POAAgent.Plugins.Transfers.WebSocket.Primus

  alias POAAgent.Entity.Host.Information

  defmodule State do
    @moduledoc false

    defstruct [
      :address,
      :identifier,
      :name,
      :secret,
      :contact
    ]
  end

  @ping_frequency 3_000

  def init_transfer(_) do
    false = Process.flag(:trap_exit, true)

    context = struct!(Primus.State, Application.get_env(:poa_agent, Primus))
    state = nil
    address = Map.fetch!(context, :address)
    {:ok, client} = Primus.Client.start_link(address, state)

    event = information()
    |> Primus.encode(context)
    |> Jason.encode!()
    :ok = Primus.Client.send(client, event)

    set_ping_timer()

    {:ok, %{client: client, context: context}}
  end

  def data_received(label, data, %{client: client, context: context} = state) when is_list(data) do
    require Logger
    Logger.info("Received data from the collector referenced by label: #{label}.")

    :ok = Enum.each(data, fn(message) ->
      event =
      message
      |> Primus.encode(context)
      |> Jason.encode!()
      :ok = Primus.Client.send(client, event)
    end)

    {:ok, state}
  end
  def data_received(label, data, state) do
    data_received(label, [data], state)
  end

  def handle_message(:ping, %{client: client, context: context} = state) do

    event = %{}
    |> Map.put(:id, context.identifier)
    |> Map.put(:clientTime, POAAgent.Utils.system_time())
    |> POAAgent.Format.PrimusEmitter.wrap(event: "node-ping")
    |> Jason.encode!()

    :ok = Primus.Client.send(client, event)

    set_ping_timer()

    {:ok, state}
  end

  def handle_message({:EXIT, client, {:remote, :closed}}, %{client: client, context: context} = state) do
    :timer.sleep(8 * 1000)

    address = Map.fetch!(context, :address)
    {:ok, client} = Primus.Client.start_link(address, nil)

    event = information()
    |> Primus.encode(context)
    |> Jason.encode!()

    :ok = Primus.Client.send(client, event)    
    
    {:ok, %{state | client: client}}
  end

  def terminate(_) do
    :ok
  end

  def encode(%Host.Information{} = x, %Primus.State{identifier: i, secret: s}) do
    x = Entity.NameConvention.from_elixir_to_node(x)

    %{}
    |> Map.put(:id, i)
    |> Map.put(:secret, s)
    |> Map.put(:info, x)
    |> POAAgent.Format.PrimusEmitter.wrap(event: "hello")
  end

  def encode(%Ethereum.Block{} = x, %Primus.State{identifier: i}) do
    x = Entity.NameConvention.from_elixir_to_node(x)

    %{}
    |> Map.put(:id, i)
    |> Map.put(:block, x)
    |> POAAgent.Format.PrimusEmitter.wrap(event: "block")
  end

  def encode(%Ethereum.Statistics{} = x, %Primus.State{identifier: i}) do
    x = Entity.NameConvention.from_elixir_to_node(x)

    %{}
    |> Map.put(:id, i)
    |> Map.put(:stats, x)
    |> POAAgent.Format.PrimusEmitter.wrap(event: "stats")
  end

  def encode(%POAAgent.Entity.Ethereum.History{} = x, %Primus.State{identifier: i}) do
    history = for i <- x.history do
      Entity.NameConvention.from_elixir_to_node(i)
    end

    %{}
    |> Map.put(:id, i)
    |> Map.put(:history, history)
    |> POAAgent.Format.PrimusEmitter.wrap(event: "history")
  end

  def encode(%POAAgent.Entity.Ethereum.Pending{} = x, %Primus.State{identifier: i}) do
    x = Entity.NameConvention.from_elixir_to_node(x)

    %{}
    |> Map.put(:id, i)
    |> Map.put(:stats, x)
    |> POAAgent.Format.PrimusEmitter.wrap(event: "pending")
  end

  def information() do
    config = Application.get_env(:poa_agent, __MODULE__)

    with {:ok, coinbase} <- Ethereumex.HttpClient.eth_coinbase(),
         {:ok, protocol} <-  Ethereumex.HttpClient.eth_protocol_version(),
         {:ok, node} <- Ethereumex.HttpClient.web3_client_version(),
         {:ok, net} <- Ethereumex.HttpClient.net_version()
    do
      %Information{
        Information.new() |
          name: config[:name],
          contact: config[:contact],
          coinbase: coinbase,
          protocol: String.to_integer(protocol),
          node: node,
          net: net
      }
    else
      _error -> Information.new()
    end
  end

  defp set_ping_timer() do
    Process.send_after(self(), :ping, @ping_frequency)
  end

  defmodule Client do
    @moduledoc false

    use WebSockex

    def send(handle, message) do
      WebSockex.send_frame(handle, {:text, message})
    end

    def start_link(address, state) do
      WebSockex.start_link(address, __MODULE__, state)
    end

    def handle_frame({:text, event}, state) do
      event = Jason.decode!(event)

      handle_primus_event(event["emit"], state)
    end
    def handle_frame({_type, _msg} = frame, state) do
      require Logger

      Logger.info("got an unexpected frame: #{inspect frame}")
      {:ok, state}
    end

    defp handle_primus_event(["node-pong", data], state) do
      context = struct!(Primus.State, Application.get_env(:poa_agent, Primus))

      now = POAAgent.Utils.system_time()
      latency = Float.ceil((now - data["clientTime"]) / 2)

      event = %{}
      |> Map.put(:id, context.identifier)
      |> Map.put(:latency, latency)
      |> POAAgent.Format.PrimusEmitter.wrap(event: "latency")
      |> Jason.encode!()

      {:reply, {:text, event}, state}
    end
    defp handle_primus_event(["history", %{"max" => max, "min" => min}], state) do
      context = struct!(Primus.State, Application.get_env(:poa_agent, Primus))

      h = POAAgent.Plugins.Collectors.Eth.LatestBlock.history(min..max)

      history = for i <- h.history do
        Entity.NameConvention.from_elixir_to_node(i)
      end

      event = %{}
      |> Map.put(:id, context.identifier)
      |> Map.put(:history, history)
      |> POAAgent.Format.PrimusEmitter.wrap(event: "history")
      |> Jason.encode!()

      {:reply, {:text, event}, state}
    end
    defp handle_primus_event(["history", false], state) do
      epoch = 20
      {:ok, num} = Ethereumex.HttpClient.eth_block_number()
      num = String.to_integer(POAAgent.Format.Literal.Hex.decimalize(num))
      {:reply, {:text, event}, state} = handle_primus_event(["history", %{"max" => num, "min" => num - epoch}], state)
      {:reply, {:text, event}, state}
    end
    defp handle_primus_event(data, state) do
      require Logger

      Logger.info("got an unexpected message: #{inspect data}")
      {:ok, state}
    end

    # def terminate(_, _) do
    #   exit(:normal)
    # end
  end
end

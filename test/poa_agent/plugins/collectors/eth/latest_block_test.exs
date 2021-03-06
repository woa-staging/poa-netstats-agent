defmodule POAAgent.Plugins.Collectors.Eth.LatestBlockTest do
  use ExUnit.Case
  import Mock

  test "latest block sent to the transfer" do
    with_mock Ethereumex.HttpClient, [
        eth_get_block_by_number: fn(_, _) -> {:ok, ethereumex_block()} end,
        eth_block_number: fn() -> {:ok, 0} end
      ] do

      {:transfer, block, _} = POAAgent.Plugins.Collectors.Eth.LatestBlock.collect(%{last_block: 1})
      assert block == expected_block()
    end
  end

  defp ethereumex_block() do
    %{"author" => "0xdf9c9701e434c5c9f755ef8af18d6a4336550206",
      "difficulty" => "0xfffffffffffffffffffffffffffffffd",
      "extraData" => "0xd583010a008650617269747986312e32342e31826c69",
      "gasLimit" => "0x7a1200",
      "gasUsed" => "0x0",
      "hash" =>
      "0xf974c07ac165f8490ef225d47f24b81161e2f2bd8ffd5b926a1a37bb22a02462",
      "miner" => "0xdf9c9701e434c5c9f755ef8af18d6a4336550206",
      "number" => "0x3b7d9",
      "parentHash" => "0xaf6f3c960045aea9edda21e119984028211f4eb3233700c18efca4f8e4c0c2fc",
      "receiptsRoot" => "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
      "sealFields" => ["0x841230dcf5", "0xb841b5ebbb6d5ff185598a86d5e96d9a238ed020b239e94eb1219a6ce1e425c7f23b768ce411474e935c2e3ee61f812ded702e1b7ca2d1c41ab4053f4420440b651901"],
      "sha3Uncles" => "0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347",
      "signature" => "b5ebbb6d5ff185598a86d5e96d9a238ed020b239e94eb1219a6ce1e425c7f23b768ce411474e935c2e3ee61f812ded702e1b7ca2d1c41ab4053f4420440b651901",
      "size" => "0x243",
      "stateRoot" => "0x590452386894d2ff6ec146a23f61fd0f459259bf0e20c59504c7f2fa3e4feeb1",
      "step" => "305192181",
      "timestamp" => "0x5af450c9",
      "totalDifficulty" => "0x3b7d8ffffffffffffffffffffffffedcd6b32", "transactions" => [],
      "transactionsRoot" => "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
      "uncles" => []}
  end

  defp expected_block() do
    %POAAgent.Entity.Ethereum.Block{
      author: "0xdf9c9701e434c5c9f755ef8af18d6a4336550206",
      difficulty: "340282366920938463463374607431768211453",
      extra_data: "0xd583010a008650617269747986312e32342e31826c69",
      gas_limit: 8_000_000,
      gas_used: 0,
      hash: "0xf974c07ac165f8490ef225d47f24b81161e2f2bd8ffd5b926a1a37bb22a02462",
      miner: "0xdf9c9701e434c5c9f755ef8af18d6a4336550206",
      number: 243_673,
      parent_hash: "0xaf6f3c960045aea9edda21e119984028211f4eb3233700c18efca4f8e4c0c2fc",
      receipts_root: "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
      seal_fields: ["0x841230dcf5", "0xb841b5ebbb6d5ff185598a86d5e96d9a238ed020b239e94eb1219a6ce1e425c7f23b768ce411474e935c2e3ee61f812ded702e1b7ca2d1c41ab4053f4420440b651901"],
      sha3_uncles: "0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347",
      signature: "b5ebbb6d5ff185598a86d5e96d9a238ed020b239e94eb1219a6ce1e425c7f23b768ce411474e935c2e3ee61f812ded702e1b7ca2d1c41ab4053f4420440b651901",
      size: 579,
      state_root: "0x590452386894d2ff6ec146a23f61fd0f459259bf0e20c59504c7f2fa3e4feeb1",
      step: "305192181",
      timestamp: 1_525_960_905,
      total_difficulty: "82917625194725838207510880716721255084813106",
      transactions: [],
      transactions_root: "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
      uncles: []
    }
  end
end

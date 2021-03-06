# POAAgent

[![Coverage Status](https://coveralls.io/repos/github/poanetwork/poa-netstats-agent/badge.svg?branch=master)](https://coveralls.io/github/poanetwork/poa-netstats-agent?branch=master)
[![codecov](https://codecov.io/gh/poanetwork/poa-netstats-agent/branch/master/graph/badge.svg)](https://codecov.io/gh/poanetwork/poa-netstats-agent)

**TODO: Add description**

## Documentation

In order to create the documentation

```
mix docs
```

## Run

POAAgent is an Elixir application, in order to run it first we need to fetch the dependencies and compile it.

```
mix deps.get
mix deps.compile
mix compile
```

## Run Tests

In order to run the tests we have to run the command

```
mix test
```

`POAAgent` comes also with a code analysis tool [Credo](https://github.com/rrrene/credo) and a types checker tool [Dialyxir](https://github.com/jeremyjh/dialyxir). In order to run them we have to run

```
mix credo
mix dialyzer
```

## Coverage

To get an HTML coverage report on your own machine try `env MIX_ENV=test mix coveralls.html` then open `cover/excoveralls.html`.
You can get a simple print-out with `env MIX_ENV=test mix coveralls`.

# ClickhouseEcto

Ecto driver for ClickHouse database using HTTP interface.

## Installation

The package can be installed
by adding `clickhouse_ecto` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:clickhouse_ecto, "~> 0.1.0"}
  ]
end
```

## Configuration
Add configuration for your repo like this:

```elixir
config :my_app, MyApp.ClickHouseRepo,
       adapter: ClickhouseEcto,
       loggers: [Ecto.LogEntry],
       hostname: "localhost",
       port: 8123,
       database: "default",
       username: "user",
       password: "654321",
       timeout: 60_000,
       pool_timeout: 60_000,
       ownership_timeout: 60_000,
       pool_size: 30
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/clickhouse_ecto](https://hexdocs.pm/clickhouse_ecto).


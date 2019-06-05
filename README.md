# ClickhouseEcto

Ecto adapter for ClickHouse database using [clickhousex driver](http://github.com/appodeal/clickhousex).

## Installation

The package can be installed
by adding `clickhouse_ecto` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:clickhouse_ecto, "~> 0.2.8"}
  ]
end
```

## Configuration
Add configuration for your repo like this:

```elixir
config :example_app, ExampleApp.ClickHouseRepo,
       adapter: ClickhouseEcto,
       loggers: [Ecto.LogEntry],
       hostname: "localhost",
       port: 8123,
       database: "example_app",
       username: "user",
       password: "654321",
       timeout: 60_000,
       pool_timeout: 60_000,
       ownership_timeout: 60_000,
       pool_size: 30
```

Do not forget to add :clickhouse_ecto and :clickhousex to your
applications:

```elixir
  def application do
    [
      mod: {ExampleApp, []},
      applications: [
        :clickhousex, :clickhouse_ecto
      ]
    ]
  end
```

## Examples

Example of Ecto model:

```elixir
defmodule ExampleApp.Click do
  use ExampleApp.Web, :model

  @primary_key {:date, :date, []}
  @timestamps_opts updated_at: false

  schema "clicks" do
    field :site_id, :integer
    field :source, :string
    field :ip, :string
    field :score, :decimal
    field :width, :integer
    field :height, :integer

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:site_id, :source, :ip, :points, :width, :height, :date])
    |> validate_required([:date, :site_id])
  end
end
```

Due to ClickHouse does not support data update and uniq rows
identifiers, do not forget to set primary key field and turn off
updated_at timestamp updating:

```elixir
  @primary_key {:date, :date, []}
  @timestamps_opts updated_at: false
```

Example of data migrations:

```elixir
defmodule ExampleApp.Repo.Migrations.CreateClick do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:clicks, engine: "MergeTree(date,(date,inserted_at,source,site_id,ip,score,width,height),8192)") do
      add :site_id, :integer, default: 0
      add :source, :string, default: ""
      add :ip, :string, default: ""
      add :score, :float, default: 0.0
      add :width, :integer
      add :height, :integer

      add :date, :date, default: :today
      timestamps(updated_at: false)
    end
  end
end

defmodule ExampleApp.Repo.Migrations.AddUserAgentToClicks do
  use Ecto.Migration

  def change do
    alter table(:clicks) do
      add :user_agent, :string
    end
  end
end
```

Queries examples:

```elixir
iex(1)> ExampleApp.Repo.insert %ExampleApp.Click{site_id: 1, date: Ecto.Date.utc, score: 1.1}
[debug] QUERY OK db=7.8ms
INSERT INTO "clicks" ("date","score","site_id","inserted_at") VALUES (?,?,?,?) [{2018, 4, 5}, 1.1, 1, {{2018, 4, 5}, {8, 18, 30, 727360}}]
{:ok,
 %ExampleApp.Click{__meta__: #Ecto.Schema.Metadata<:loaded, "clicks">,
  date: #Ecto.Date<2018-04-05>, height: nil,
  inserted_at: ~N[2018-04-05 08:18:30.727360], ip: nil, score: 1.1, site_id: 1,
  source: nil, width: nil}}
iex(2)> ExampleApp.Repo.all ExampleApp.Click
[debug] QUERY OK source="clicks" db=11.8ms
SELECT c0."date", c0."site_id", c0."source", c0."ip", c0."score", c0."width", c0."height", c0."inserted_at" FROM "clicks" AS c0 []
[%ExampleApp.Click{__meta__: #Ecto.Schema.Metadata<:loaded, "clicks">,
  date: ~D[2018-04-05], height: 0, inserted_at: ~N[2018-04-05 09:15:42.000000],
  ip: "", score: #Decimal<1.1>, site_id: 1, source: "", width: 0}]
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/clickhouse_ecto](https://hexdocs.pm/clickhouse_ecto).


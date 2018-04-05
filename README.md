# ClickhouseEcto

Ecto driver for ClickHouse database using HTTP interface.

## Installation

The package can be installed
by adding `clickhouse_ecto` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:clickhouse_ecto, "~> 0.2.0"}
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

## Examples

Example of Ecto model:

```Elixir
defmodule ExampleApp.User do
  use ExampleApp.Web, :model

  schema "clicks" do
    field :site_id, :integer
    field :source, :string
    field :ip, :string
    field :points, :decimal
    field :width, :integer
    field :height, :integer
    field :date, :date

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

Example of data migrations:

```Elixir
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

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/clickhouse_ecto](https://hexdocs.pm/clickhouse_ecto).


defmodule ClickhouseEctoTest do
  use ExUnit.Case
  doctest ClickhouseEcto

  import Ecto.Query

  alias ClickhouseEcto.Connection, as: SQL


  defmodule Schema do
    use Ecto.Schema

    schema "test" do
      field :app_id, :integer
      field :country_id, :integer
      field :android_id, :string
    end
  end

  test "select" do
    query = Schema |> select([r], {r.x, r.y}) |> normalize
    assert SQL.all(query) == ~s{SELECT s0."x", s0."y" FROM "schema" AS s0}

    query = Schema |> select([r], [r.x, r.y]) |> normalize
    assert SQL.all(query) == ~s{SELECT s0."x", s0."y" FROM "schema" AS s0}

    query = Schema |> select([r], struct(r, [:x, :y])) |> normalize
    assert SQL.all(query) == ~s{SELECT s0."x", s0."y" FROM "schema" AS s0}
  end
end


defmodule ClickhouseEcto.InsertTest  do

use ExUnit.Case
import Ecto.Query



alias ClickhouseEcto.Connection, as: SQL


defp insert(prefx, table, header, rows, on_conflict, returning) do
  IO.iodata_to_binary SQL.insert(prefx, table, header, rows, on_conflict, returning)
end

  test "insert" do
    query = insert(nil, "schema", [:x, :y], [[:x, :y]], {:raise, [], []}, [])
    assert query == ~s{INSERT INTO "schema" ("x","y") VALUES (?,?)}

    query = insert(nil, "schema", [:x, :y], [[:x, :y], [nil, :y]], {:raise, [], []}, [])
    assert query == ~s{INSERT INTO "schema" ("x","y") VALUES (?,?),(DEFAULT,?)}

    query = insert(nil, "schema", [], [[]], {:raise, [], []}, [])
    assert query == ~s{INSERT INTO "schema" () VALUES ()}

    query = insert("prefix", "schema", [], [[]], {:raise, [], []}, [])
    assert query == ~s{INSERT INTO "prefix"."schema" () VALUES ()}
  end

end

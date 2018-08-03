defmodule ClickhouseEctoTest do
  use ExUnit.Case
  doctest ClickhouseEcto

  import Ecto.Query

  alias ClickhouseEcto.Connection, as: SQL

  defmodule Schema do
    use Ecto.Schema

    schema "schema" do
      field :x, :integer
      field :y, :integer
      field :z, :integer
    end
  end

  defp normalize(query, operation \\ :all, counter \\ 0) do
    {query, _params, _key} = Ecto.Query.Planner.prepare(query, operation, ClickhouseEcto, counter)
    {query, _} = Ecto.Query.Planner.normalize(query, operation, ClickhouseEcto, counter)
    query
  end


  defp all(query), do: query |> SQL.all |> IO.iodata_to_binary()

  defp insert(prefx, table, header, rows, on_conflict, returning) do
    IO.iodata_to_binary SQL.insert(prefx, table, header, rows, on_conflict, returning)
  end

  test "from" do
    query = Schema |> select([r], r.x) |> normalize
    assert all(query) == ~s{SELECT s0."x" FROM "schema" AS s0}
  end

  test "from without schema" do
    query = "posts" |> select([r], r.x) |> normalize
    assert all(query) == ~s{SELECT p0."x" FROM "posts" AS p0}

    query = "Posts" |> select([:x]) |> normalize
    assert all(query) == ~s{SELECT P0."x" FROM "Posts" AS P0}

# FIXME
#     query = "0posts" |> select([:x]) |> normalize
#     assert all(query) == ~s{SELECT t0."x" FROM "0posts" AS t0}

#     assert_raise Ecto.QueryError, ~r/MySQL does not support selecting all fields from "posts" without a schema/, fn ->
#       all from(p in "posts", select: p) |> normalize()
#     end
  end

  test "from with subquery" do
    query = subquery("posts" |> select([r], %{x: r.x, y: r.y})) |> select([r], r.x) |> normalize
    assert all(query) == ~s{SELECT s0."x" FROM (SELECT p0."x" AS "x", p0."y" AS "y" FROM "posts" AS p0) AS s0}

    query = subquery("posts" |> select([r], %{x: r.x, z: r.y})) |> select([r], r) |> normalize
    assert all(query) == ~s{SELECT s0."x", s0."z" FROM (SELECT p0."x" AS "x", p0."y" AS "z" FROM "posts" AS p0) AS s0}
  end

  test "select" do
    query = Schema |> select([r], {r.x, r.y}) |> normalize
    assert all(query) == ~s{SELECT s0."x", s0."y" FROM "schema" AS s0}

    query = Schema |> select([r], [r.x, r.y]) |> normalize
    assert all(query) == ~s{SELECT s0."x", s0."y" FROM "schema" AS s0}

    query = Schema |> select([r], struct(r, [:x, :y])) |> normalize
    assert all(query) == ~s{SELECT s0."x", s0."y" FROM "schema" AS s0}
  end

  test "distinct" do
    query = Schema |> distinct([r], true) |> select([r], {r.x, r.y}) |> normalize
    assert all(query) == ~s{SELECT DISTINCT s0."x", s0."y" FROM "schema" AS s0}

    query = Schema |> distinct([r], false) |> select([r], {r.x, r.y}) |> normalize
    assert all(query) == ~s{SELECT s0."x", s0."y" FROM "schema" AS s0}

    query = Schema |> distinct(true) |> select([r], {r.x, r.y}) |> normalize
    assert all(query) == ~s{SELECT DISTINCT s0."x", s0."y" FROM "schema" AS s0}

    query = Schema |> distinct(false) |> select([r], {r.x, r.y}) |> normalize
    assert all(query) == ~s{SELECT s0."x", s0."y" FROM "schema" AS s0}

    assert_raise Ecto.QueryError, ~r"DISTINCT ON is not supported", fn ->
      query = Schema |> distinct([r], [r.x, r.y]) |> select([r], {r.x, r.y}) |> normalize
      all(query)
    end
  end

  test "where" do
    query = Schema |> where([r], r.x == 42) |> where([r], r.y != 43) |> select([r], r.x) |> normalize
    assert all(query) == ~s{SELECT s0."x" FROM "schema" AS s0 WHERE (s0."x" = 42) AND (s0."y" != 43)}
  end

  test "or_where" do
    query = Schema |> or_where([r], r.x == 42) |> or_where([r], r.y != 43) |> select([r], r.x) |> normalize
    assert all(query) == ~s{SELECT s0."x" FROM "schema" AS s0 WHERE (s0."x" = 42) OR (s0."y" != 43)}

    query = Schema |> or_where([r], r.x == 42) |> or_where([r], r.y != 43) |> where([r], r.z == 44) |> select([r], r.x) |> normalize
    assert all(query) == ~s{SELECT s0."x" FROM "schema" AS s0 WHERE ((s0."x" = 42) OR (s0."y" != 43)) AND (s0."z" = 44)}
  end

  test "order by" do
    query = Schema |> order_by([r], r.x) |> select([r], r.x) |> normalize
    assert all(query) == ~s{SELECT s0."x" FROM "schema" AS s0 ORDER BY s0."x"}

    query = Schema |> order_by([r], [r.x, r.y]) |> select([r], r.x) |> normalize
    assert all(query) == ~s{SELECT s0."x" FROM "schema" AS s0 ORDER BY s0."x", s0."y"}

    query = Schema |> order_by([r], [asc: r.x, desc: r.y]) |> select([r], r.x) |> normalize
    assert all(query) == ~s{SELECT s0."x" FROM "schema" AS s0 ORDER BY s0."x", s0."y" DESC}

    query = Schema |> order_by([r], []) |> select([r], r.x) |> normalize
    assert all(query) == ~s{SELECT s0."x" FROM "schema" AS s0}
  end

  test "limit and offset" do
    query = Schema |> limit([r], 3) |> select([], true) |> normalize
    assert all(query) == ~s{SELECT 'TRUE' FROM "schema" AS s0 LIMIT 3}

    query = Schema |> offset([r], 5) |> limit([r], 3) |> select([], true) |> normalize
    assert all(query) == ~s{SELECT 'TRUE' FROM "schema" AS s0 LIMIT 5, 3}
  end

  test "string escape" do
    # FIXME
    # query = "schema" |> where(foo: "'\\  ") |> select([], true) |> normalize
    # assert all(query) == ~s{SELECT 'TRUE' FROM "schema" AS s0 WHERE (s0."foo" = '''\\\\  ')}

    query = "schema" |> where(foo: "'") |> select([], true) |> normalize
    assert all(query) == ~s{SELECT 'TRUE' FROM "schema" AS s0 WHERE (s0."foo" = '''')}
  end

  test "binary ops" do
    query = Schema |> select([r], r.x == 2) |> normalize
    assert all(query) == ~s{SELECT s0."x" = 2 FROM "schema" AS s0}

    query = Schema |> select([r], r.x != 2) |> normalize
    assert all(query) == ~s{SELECT s0."x" != 2 FROM "schema" AS s0}

    query = Schema |> select([r], r.x <= 2) |> normalize
    assert all(query) == ~s{SELECT s0."x" <= 2 FROM "schema" AS s0}

    query = Schema |> select([r], r.x >= 2) |> normalize
    assert all(query) == ~s{SELECT s0."x" >= 2 FROM "schema" AS s0}

    query = Schema |> select([r], r.x < 2) |> normalize
    assert all(query) == ~s{SELECT s0."x" < 2 FROM "schema" AS s0}

    query = Schema |> select([r], r.x > 2) |> normalize
    assert all(query) == ~s{SELECT s0."x" > 2 FROM "schema" AS s0}
  end

  test "is_nil" do
    query = Schema |> select([r], is_nil(r.x)) |> normalize
    assert all(query) == ~s{SELECT s0."x" IS NULL FROM "schema" AS s0}

    query = Schema |> select([r], not is_nil(r.x)) |> normalize
    assert all(query) == ~s{SELECT NOT (s0."x" IS NULL) FROM "schema" AS s0}
  end

  test "fragments" do
    query = Schema |> select([r], fragment("lcase(?)", r.x)) |> normalize
    assert all(query) == ~s{SELECT lcase(s0."x") FROM "schema" AS s0}

    query = Schema |> select([r], r.x) |> where([], fragment("? = \"query\\?\"", ^10)) |> normalize
    assert all(query) == ~s{SELECT s0."x" FROM "schema" AS s0 WHERE (? = \"query?\")}

    value = 13
    query = Schema |> select([r], fragment("lcase(?, ?)", r.x, ^value)) |> normalize
    assert all(query) == ~s{SELECT lcase(s0."x", ?) FROM "schema" AS s0}

    query = Schema |> select([], fragment(title: 2)) |> normalize
    assert_raise Ecto.QueryError, fn ->
      all(query)
    end
  end

  test "literals" do
    query = "schema" |> where(foo: true) |> select([], true) |> normalize
    assert all(query) == ~s{SELECT 'TRUE' FROM "schema" AS s0 WHERE (s0."foo" = 1)}

    query = "schema" |> where(foo: false) |> select([], true) |> normalize
    assert all(query) == ~s{SELECT 'TRUE' FROM "schema" AS s0 WHERE (s0."foo" = 0)}

    query = "schema" |> where(foo: "abc") |> select([], true) |> normalize
    assert all(query) == ~s{SELECT 'TRUE' FROM "schema" AS s0 WHERE (s0."foo" = 'abc')}

    query = "schema" |> where(foo: 123) |> select([], true) |> normalize
    assert all(query) == ~s{SELECT 'TRUE' FROM "schema" AS s0 WHERE (s0."foo" = 123)}

    query = "schema" |> where(foo: 123.0) |> select([], true) |> normalize
    assert all(query) == ~s{SELECT 'TRUE' FROM "schema" AS s0 WHERE (s0."foo" = 123.0)}
  end

  test "tagged type" do
    query = Schema |> select([], type(^"601d74e4-a8d3-4b6e-8365-eddb4c893327", Ecto.UUID)) |> normalize
    assert all(query) == ~s{SELECT CAST(? AS FixedString(36)) FROM "schema" AS s0}
  end

  test "string type" do
    query = Schema |> select([], type(^"test", :string)) |> normalize
    assert all(query) == ~s{SELECT CAST(? AS String) FROM "schema" AS s0}
  end

  test "nested expressions" do
    z = 123
    query = from(r in Schema, []) |> select([r], r.x > 0 and (r.y > ^(-z)) or true) |> normalize
    assert all(query) == ~s{SELECT ((s0."x" > 0) AND (s0."y" > ?)) OR 1 FROM "schema" AS s0}
  end

  test "in expression" do
    query = Schema |> select([e], 1 in []) |> normalize
    assert all(query) == ~s{SELECT 0=1 FROM "schema" AS s0}

    query = Schema |> select([e], 1 in [1,e.x,3]) |> normalize
    assert all(query) == ~s{SELECT 1 IN (1,s0."x",3) FROM "schema" AS s0}

    query = Schema |> select([e], 1 in ^[]) |> normalize
    assert all(query) == ~s{SELECT 0=1 FROM "schema" AS s0}

    query = Schema |> select([e], 1 in ^[1, 2, 3]) |> normalize
    assert all(query) == ~s{SELECT 1 IN (?,?,?) FROM "schema" AS s0}

    query = Schema |> select([e], 1 in [1, ^2, 3]) |> normalize
    assert all(query) == ~s{SELECT 1 IN (1,?,3) FROM "schema" AS s0}

    query = Schema |> select([e], 1 in fragment("foo")) |> normalize
    assert all(query) == ~s{SELECT 1 = ANY(foo) FROM "schema" AS s0}

    query = Schema |> select([e], e.x == ^0 or e.x in ^[1, 2, 3] or e.x == ^4) |> normalize
    assert all(query) == ~s{SELECT ((s0."x" = ?) OR (s0."x" IN (?,?,?))) OR (s0."x" = ?) FROM "schema" AS s0}
  end

  test "having" do
    query = Schema |> having([p], p.x == p.x) |> select([p], p.x) |> normalize
    assert all(query) == ~s{SELECT s0."x" FROM "schema" AS s0 HAVING (s0."x" = s0."x")}

    query = Schema |> having([p], p.x == p.x) |> having([p], p.y == p.y) |> select([p], [p.y, p.x]) |> normalize
    assert all(query) == ~s{SELECT s0."y", s0."x" FROM "schema" AS s0 HAVING (s0."x" = s0."x") AND (s0."y" = s0."y")}
  end

  test "or_having" do
    query = Schema |> or_having([p], p.x == p.x) |> select([p], p.x) |> normalize
    assert all(query) == ~s{SELECT s0."x" FROM "schema" AS s0 HAVING (s0."x" = s0."x")}

    query = Schema |> or_having([p], p.x == p.x) |> or_having([p], p.y == p.y) |> select([p], [p.y, p.x]) |> normalize
    assert all(query) == ~s{SELECT s0."y", s0."x" FROM "schema" AS s0 HAVING (s0."x" = s0."x") OR (s0."y" = s0."y")}
  end

  test "group by" do
    query = Schema |> group_by([r], r.x) |> select([r], r.x) |> normalize
    assert all(query) == ~s{SELECT s0."x" FROM "schema" AS s0 GROUP BY s0."x"}

    query = Schema |> group_by([r], 2) |> select([r], r.x) |> normalize
    assert all(query) == ~s{SELECT s0."x" FROM "schema" AS s0 GROUP BY 2}

    query = Schema |> group_by([r], [r.x, r.y]) |> select([r], r.x) |> normalize
    assert all(query) == ~s{SELECT s0."x" FROM "schema" AS s0 GROUP BY s0."x", s0."y"}

    query = Schema |> group_by([r], []) |> select([r], r.x) |> normalize
    assert all(query) == ~s{SELECT s0."x" FROM "schema" AS s0}
  end

  test "interpolated values" do
    query = Schema
            |> select([m], {m.id, ^0})
            |> where([], fragment("?", ^true))
            |> where([], fragment("?", ^false))
            |> having([], fragment("?", ^true))
            |> having([], fragment("?", ^false))
            |> group_by([], fragment("?", ^1))
            |> group_by([], fragment("?", ^2))
            |> order_by([], fragment("?", ^3))
            |> order_by([], ^:x)
            |> limit([], ^4)
            |> offset([], ^5)
            |> normalize

    result =
      ~s{SELECT s0."id", ? FROM "schema" AS s0 } <>
      ~s{WHERE (?) AND (?) GROUP BY ?, ? HAVING (?) AND (?) } <>
      ~s{ORDER BY ?, s0."x" LIMIT ?, ?}

    assert all(query) == String.trim(result)
  end

  # Schema based

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

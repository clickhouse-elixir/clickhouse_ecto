defmodule ClickhouseEcto.Query do

  alias ClickhouseEcto.QueryString

  import ClickhouseEcto.Helpers

  require IEx

  @doc """
  Receives a query and must return a SELECT query.
  """
  @spec all(query :: Ecto.Query.t) :: String.t
  def all(query) do
    sources = QueryString.create_names(query)
    {select_distinct, order_by_distinct} = QueryString.distinct(query.distinct, sources, query)

    from     = QueryString.from(query, sources)
    select   = QueryString.select(query, select_distinct, sources)
    join     = QueryString.join(query, sources)
    where    = QueryString.where(query, sources)
    group_by = QueryString.group_by(query, sources)
    having   = QueryString.having(query, sources)
    order_by = QueryString.order_by(query, order_by_distinct, sources)
    limit    = QueryString.limit(query, sources)
    #lock     = QueryString.lock(query.lock)

    #res = [select, from, join, where, group_by, having, order_by, lock]
    #res = [select, from, join, where, group_by, having, order_by, offset | lock]
    res = [select, from, join, where, group_by, having, order_by, limit]

    IO.iodata_to_binary(res)
  end

  @doc """
  Returns an INSERT for the given `rows` in `table` returning
  the given `returning`.
  """
  @spec insert(prefix ::String.t, table :: String.t,
          header :: [atom], rows :: [[atom | nil]],
          on_conflict :: Ecto.Adapter.on_conflict, returning :: [atom]) :: String.t
  def insert(prefix, table, header, rows, on_conflict, returning) do
    included_fields = header
                      |> Enum.filter(fn value -> Enum.any?(rows, fn row -> value in row end) end)

    included_rows =
      Enum.map(rows, fn row ->
        row
        |> Enum.zip(header)
        |> Enum.filter_map(
             fn {_row, col} -> col in included_fields end,
             fn {row, _col} -> row end)
      end)

    fields = intersperse_map(included_fields, ?,, &quote_name/1)
    query = [
      "INSERT INTO ", quote_table(prefix, table),
      " (", fields, ")",
      " VALUES ",
      insert_all(included_rows, 1),
    ]
    IO.iodata_to_binary(query)
  end

  defp insert_all(rows, counter) do
    intersperse_reduce(rows, ?,, counter, fn row, counter ->
      {row, counter} = insert_each(row, counter)
      {[?(, row, ?)], counter}
    end)
    |> elem(0)
  end

  defp insert_each(values, counter) do
    intersperse_reduce(values, ?,, counter, fn
      nil, counter ->
        {"DEFAULT", counter}
      _, counter ->
        {[??], counter + 1}
    end)
  end

  @doc """
  Clickhouse doesn't support update
  """
  @spec update(prefix :: String.t, table :: String.t, fields :: [atom], filters :: [atom], returning :: [atom]) :: String.t
  def update(prefix, table, fields, filters, returning) do
    raise "UPDATE is not supported"
  end

  @doc """
  Clickhouse doesn't support delete
  """
  @spec delete(prefix :: String.t, table :: String.t, filters :: [atom], returning :: [atom]) :: String.t
  def delete(prefix, table, filters, returning) do
    raise "DELETE is not supported"
  end

  @doc """
  Receives a query and values to update and must return an UPDATE query.
  """
  @spec update_all(query :: Ecto.Query.t) :: String.t
  def update_all(%{from: from} = query, prefix \\ nil) do
    raise "UPDATE is not supported"
  end

  @doc """
  Clickhouse doesn't support delete
  """
  @spec delete_all(query :: Ecto.Query.t) :: String.t
  def delete_all(%{from: from} = query) do
    raise "DELETE is not supported"
  end
end

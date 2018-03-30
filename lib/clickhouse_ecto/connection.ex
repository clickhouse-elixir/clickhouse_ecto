defmodule ClickhouseEcto.Connection do
  alias Clickhousex.Query
  alias ClickhouseEcto.Query, as: SQL

  @typedoc "The prepared query which is an SQL command"
  @type prepared :: String.t

  @typedoc "The cache query which is a DBConnection Query"
  @type cached :: map

  @doc """
  Receives options and returns `DBConnection` supervisor child
  specification.
  """
  @spec child_spec(options :: Keyword.t) :: {module, Keyword.t}
  def child_spec(opts) do
    DBConnection.child_spec(Clickhousex.Protocol, opts)
  end

  @doc """
  Prepares and executes the given query with `DBConnection`.
  """
  @spec prepare_execute(connection :: DBConnection.t, name :: String.t, prepared, params :: [term], options :: Keyword.t) ::
  {:ok, query :: map, term} | {:error, Exception.t}
  def prepare_execute(conn, name, prepared_query, params, options) do
    statement = sanitise_query(prepared_query)
    ordered_params = order_params(prepared_query, params)

    case DBConnection.prepare_execute(conn, %Query{name: name, statement: statement}, ordered_params, options) do
      {:ok, query, result} ->
        #{:ok, result}
        {:ok, %{query | statement: prepared_query}, process_rows(result, options)}
      {:error, %Clickhousex.Error{}} = error ->
        if is_no_data_found_bug?(error, prepared_query) do
          {:ok, %Query{name: "", statement: prepared_query}, %{num_rows: 0, rows: []}}
        else
          error
        end
      {:error, error} -> raise error
    end
  end

  @doc """
  Executes the given prepared query with `DBConnection`.
  """
  @spec execute(connection :: DBConnection.t, prepared_query :: prepared, params :: [term], options :: Keyword.t) ::
            {:ok, term} | {:error, Exception.t}
  @spec execute(connection :: DBConnection.t, prepared_query :: cached, params :: [term], options :: Keyword.t) ::
            {:ok, term} | {:error | :reset, Exception.t}
  def execute(conn, %Query{} = query, params, options) do
    ordered_params =
      query.statement
      |> IO.iodata_to_binary
      |> order_params(params)

    sanitised_query = sanitise_query(query.statement)
    query = Map.put(query, :statement, sanitised_query)

    case DBConnection.prepare_execute(conn, query, ordered_params, options) do
      {:ok, _query, result} ->
        #{:ok, result}
        {:ok, process_rows(result, options)}
      {:error, %Clickhousex.Error{}} = error ->
        if is_no_data_found_bug?(error, query.statement) do
          {:ok, %{num_rows: 0, rows: []}}
        else
          error
        end
      {:error, error} -> raise error
    end
  end
  def execute(conn, statement, params, options) do
    execute(conn, %Query{name: "", statement: statement}, params, options)
  end

  defp order_params(query, params) do
    sanitised = Regex.replace(~r/(([^\\]|^))["'].*?[^\\]['"]/, IO.iodata_to_binary(query), "\\g{1}")

    ordering =
      Regex.scan(~r/\?([0-9]+)/, sanitised)
      |> Enum.map( fn [_, x] -> String.to_integer(x) end)

    if length(ordering) != length(params) do
      raise "\nError: number of params received (#{length(params)}) does not match expected (#{length(ordering)})"
    end

    ordered_params =
      ordering
      |> Enum.reduce([], fn ix, acc -> [Enum.at(params, ix - 1) | acc] end)
      |> Enum.reverse

    case ordered_params do
      []  -> params
      _   -> ordered_params
    end
  end

  defp sanitise_query(query) do
    query
    |> IO.iodata_to_binary
    |> String.replace(~r/(\?([0-9]+))(?=(?:[^\\"']|[\\"'][^\\"']*[\\"'])*$)/, "?")
  end

  defp is_no_data_found_bug?({:error, error}, statement) do
      is_dml = statement
      |> IO.iodata_to_binary()
      |> (fn string -> String.starts_with?(string, "INSERT") || String.starts_with?(string, "DELETE") || String.starts_with?(string, "UPDATE") end).()

      is_dml and error.message =~ "No SQL-driver information available."
  end

  defp process_rows(result, options) do
#    decoder = fn x -> x end
    decoder = options[:decode_mapper] || fn x -> x end
    Map.update!(result, :rows, fn row ->
      unless is_nil(row), do: Enum.map(row, decoder)
    end)
  end


  @doc """
  Receives the exception returned by `query/4`.
  The constraints are in the keyword list and must return the
  constraint type, like `:unique`, and the constraint name as
  a string, for example:
      [unique: "posts_title_index"]
  Must return an empty list if the error does not come
  from any constraint.
  """
  @spec to_constraints(exception :: Exception.t) :: Keyword.t
  def to_constraints(%Clickhousex.Error{} = error), do: error.constraint_violations

  @doc """
  Returns a stream that prepares and executes the given query with
  `DBConnection`.
  """
  @spec stream(connection :: DBConnection.conn, prepared_query :: prepared, params :: [term], options :: Keyword.t) ::
  Enum.t
  def stream(_conn, _prepared, _params, _options) do
    raise("not implemented")
  end

  ## Queries
  def all(query) do
    SQL.all(query)
  end
  def update_all(query, prefix \\ nil), do: SQL.update_all(query, prefix)
  @doc false
  def delete_all(query), do: SQL.delete_all(query)

  def insert(prefix, table, header, rows, on_conflict, returning),
    do: SQL.insert(prefix, table, header, rows, on_conflict, returning)
  def update(prefix, table, fields, filters, returning),
    do: SQL.update(prefix, table, fields, filters, returning)
  def delete(prefix, table, filters, returning),
    do: SQL.delete(prefix, table, filters, returning)

  ## Migration
  def execute_ddl(command), do: ClickhouseEcto.Migration.execute_ddl(command)
end

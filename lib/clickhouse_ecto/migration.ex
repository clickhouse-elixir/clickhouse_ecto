defmodule ClickhouseEcto.Migration do
  require IEx
  alias Ecto.Migration.{Table, Index, Reference, Constraint}

  import ClickhouseEcto.Helpers

  @drops [:drop, :drop_if_exists]

  @doc """
  Receives a DDL command and returns a query that executes it.
  """
  @spec execute_ddl(command :: Ecto.Adapter.Migration.command) :: String.t
  def execute_ddl({command, %Table{} = table, columns}) when command in [:create, :create_if_not_exists] do
    engine = table.engine

    {_, first_column_name, _, _} = List.first(columns)
    filtered_columns = cond do
      first_column_name == :id ->
        List.delete_at(columns, 0)
      true ->
        columns
    end

    query = [if_do(command == :create_if_not_exists, "CREATE TABLE IF NOT EXISTS ", "CREATE TABLE "),
             quote_table(table.prefix, table.name), ?\s, ?(,
             column_definitions(table, filtered_columns), ?),
             options_expr(table.options),
             if_do(engine != nil, " ENGINE = #{engine}  ", " ENGINE = TinyLog ")]

    [query]
  end

  def execute_ddl({command, %Table{} = table}) when command in @drops do
    [[if_do(command == :drop_if_exists, "DROP TABLE IF EXISTS ", "DROP TABLE "),
      quote_table(table.prefix, table.name)
    ]]
  end

  def execute_ddl({:alter, %Table{} = table, changes}) do
    query = [column_changes(table, changes)]

    [query]
  end

  # TODO: Add 'ON CLUSTER' option.
  def execute_ddl({:rename, %Table{} = current_table, %Table{} = new_table}) do
    [["RENAME TABLE ", quote_name([current_table.prefix, current_table.name]),
      " TO ", quote_name(new_table.name)]]
  end

  def execute_ddl({:rename, %Table{} = table, current_column, new_column}) do
    # https://github.com/yandex/ClickHouse/issues/146
    raise "It seems like reneaming columns is not supported..."
  end

  def execute_ddl(string) when is_binary(string), do: [string]

  def execute_ddl(keyword) when is_list(keyword),
    do: error!(nil, "Clickhouse adapter does not support keyword lists in execute")

  @doc false
  def supports_ddl_transaction? do
    false
  end

  ## Helpers

  defp quote_alter([], _table), do: []
  defp quote_alter(statement, table),
    do: ["ALTER TABLE ", quote_table(table.prefix, table.name), statement, "; "]

  defp column_definitions(table, columns) do
    intersperse_map(columns, ", ", &column_definition(table, &1))
  end

  defp column_definition(table, {:add, name, %Reference{} = ref, opts}) do
    [quote_name(name), ?\s,
     column_options(ref.type, opts, table, name)
     ]
  end

  defp column_definition(table, {:add, name, type, opts}) do
    [quote_name(name), ?\s, column_type(type, opts),
     column_options(type, opts, table, name)]
  end

  defp column_changes(table, columns) do
    {additions, changes} = Enum.split_with(columns,
      fn val -> elem(val, 0) == :add end)
    [if_do(additions !== [], column_additions(additions, table)),
     if_do(changes !== [], Enum.map(changes, &column_change(table, &1)))]
  end

  defp column_additions(additions, table) do
    Enum.map(additions, fn(addition) ->
      [" ADD COLUMN ", column_change(table, addition)]
    end)
    |> Enum.join(",")
    |> quote_alter(table)
  end

  defp column_change(table, {:add, name, %Reference{} = ref, opts}) do
    [quote_name(name), ?\s,
     column_options(ref.type, opts, table, name)]
  end

  defp column_change(table, {:add, name, type, opts}) do
    [quote_name(name), ?\s, column_type(type, opts),
     column_options(type, opts, table, name)]
  end

  defp column_change(table, {:modify, name, %Reference{} = ref, opts}) do
    [quote_alter([" MODIFY COLUMN ", quote_name(name), ?\s, modify_null(name, opts)], table),
     modify_default(name, ref.type, opts, table, name)]
  end

  defp column_change(table, {:modify, name, type, opts}) do
    [quote_alter([" MODIFY COLUMN ", quote_name(name), ?\s, column_type(type, opts),
     modify_null(name, opts)], table), modify_default(name, type, opts, table, name)]
  end

  defp column_change(table, {:remove, name}) do
    [quote_alter([" DROP COLUMN ", quote_name(name)], table)]
  end

  defp modify_null(_name, opts) do
    case Keyword.get(opts, :null) do
      nil -> []
      val -> null_expr(val)
    end
  end

  defp modify_default(name, type, opts, table, name) do
    case Keyword.fetch(opts, :default) do
      {:ok, val} ->
        [
         quote_alter([" ADD", default_expr({:ok, val}, type, table, name), " FOR ", quote_name(name)], table)]
      :error -> []
    end
  end

  defp column_options(type, opts, table, name) do
    default = Keyword.fetch(opts, :default)
    null    = Keyword.get(opts, :null)
    [default_expr(default, type, table, name), null_expr(null)]
  end

  #defp null_expr(false), do: " NOT NULL"
  defp null_expr(false), do: " "
  defp null_expr(true), do: " NULL"
  defp null_expr(_), do: []

  defp default_expr({:ok, _} = default, type, table, name),
    do: [default_expr(default, type)]
  defp default_expr(:error, _, _, _),
    do: []
  defp default_expr({:ok, nil}, _type),
    do: error!(nil, "NULL is not supported")
  defp default_expr({:ok, []}, _type),
    do: error!(nil, "arrays are not supported")
  defp default_expr({:ok, literal}, _type) when is_binary(literal),
    do: [" DEFAULT '", escape_string(literal), ?']
  defp default_expr({:ok, literal}, _type) when is_number(literal),
    do: [" DEFAULT ", to_string(literal)]
  defp default_expr({:ok, literal}, _type) when is_boolean(literal),
    do: [" DEFAULT ", to_string(if literal, do: 1, else: 0)]
  defp default_expr({:ok, :today}, :date),
       do: [" DEFAULT today()"]
  defp default_expr({:ok, {:fragment, expr}}, _type),
    do: [" DEFAULT ", expr]
  defp default_expr({:ok, expr}, type),
    do: raise(ArgumentError, "unknown default `#{inspect expr}` for type `#{inspect type}`. " <>
                             ":default may be a string, number, boolean, empty list or a fragment(...)")

  defp index_expr(literal) when is_binary(literal),
    do: literal
  defp index_expr(literal),
    do: quote_name(literal)

  defp options_expr(nil),
    do: []
  defp options_expr(keyword) when is_list(keyword),
    do: error!(nil, "ClickHouse adapter does not support keyword lists in :options")
  defp options_expr(options),
    do: [?\s, options]

  defp column_type({:array, type}, opts),
    do: [column_type(type, opts), "[]"]
  defp column_type(type, opts) do
    size      = Keyword.get(opts, :size)
    precision = Keyword.get(opts, :precision)
    scale     = Keyword.get(opts, :scale)
    type_name = ecto_to_db(type)

    cond do
      size            -> [type_name, ?(, to_string(size), ?)]
      precision       -> [type_name, ?(, to_string(precision), ?,, to_string(scale || 0), ?)]
      type == :string -> [type_name, " "]
      true            -> type_name
    end
  end

end

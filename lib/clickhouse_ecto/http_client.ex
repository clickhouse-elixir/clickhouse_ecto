defmodule ClickhouseEcto.HTTPClient do
  @moduledoc false

  alias ClickhouseEcto.Types
  alias ClickhouseEcto.Parsers
  @selected_queries_regex ~r/^(SELECT|SHOW|DESCRIBE|EXISTS)/i
  @req_headers [{"Content-Type", "text/plain"}]

  def send(query, base_address, timeout, username, password, database, method) when username != nil do
    # TODO change hackney auth
    opts = %{hackney: [basic_auth: {username, password}], timeout: timeout, recv_timeout: timeout}
    send_p(query, base_address, database, opts, method)
  end

  def send(query, base_address, timeout, username, password, database, method) when username == nil do
    send_p(query, base_address, database, %{timeout: timeout, recv_timeout: timeout}, method)
  end

  @doc false
  defp send_p(query, base_address, database, opts, method) do
    command = parse_command(query)
    query_normalized = query |> normalize_query(command)
    opts_new = Map.merge(opts, %{params: %{database: database}})

    res = MachineGun.request(method, base_address, query_normalized, @req_headers, opts_new)
    case res do
      {:ok, resp} ->
        cond do
          resp.status_code == 200 ->
            case command do
              :selected ->
                # FIXME insert database here
                {fields ,table} = parse_table(query_normalized) #|> IO.inspect
                query_normalized #|> IO.inspect
                table  #|> IO.inspect
                desc = MachineGun.request!(:post, base_address,
                "DESCRIBE TABLE "<>  Enum.join(table, ",") <> "FORMAT JSON", [], %{})

                {type, name} = Parsers.parse_types(desc.body, fields) |> Enum.unzip
                columns = name
                rows = Parsers.row_binary_parser(resp.body, type)
                # JSON REALISATION
                # case Poison.decode(resp.body) do
                #   {:ok, %{"meta" => meta, "data" => data, "rows" => _rows_count}} ->
                #     columns = meta |> Enum.map(fn(%{"name" => name, "type" => _type}) -> name end)
                #     rows = data |> Enum.map(fn(data_row) ->
                #       meta
                #       |> Enum.map(fn(%{"name" => column, "type" => column_type}) ->
                #         Types.decode(data_row[column], column_type)
                #       end)
                #       |> List.to_tuple()
                #     end)
                #     {command, columns, rows}
                #   {:error, reason} -> {:error, reason}
                # end
                {:selected, rows, columns}
              :updated ->
                {:updated, 1}
            end
          true ->
            {:error, resp.body}
        end
      {:error, error} ->
        {:error, error.reason}
    end
  end

  defp parse_command(query) do
    cond do
      query =~ @selected_queries_regex -> :selected
      true -> :updated
    end
  end

  defp normalize_query(query, command) do
    case command do
      :selected -> query_with_format(query)
      _ -> query
    end
  end
  defp parse_table(query) do
    # here need to parse query to extract name of table
    # name table should be between SELECT FROM ... WHERE/GROUP BY or nothing
    result = Regex.split(~r/(SELECT|FROM|WHERE|GROUP BY|AS|FORMAT) */, query)

    tables = Enum.at(result, 2) |> IO.inspect


    fields = Enum.at(result, 1) |> IO.inspect

    intersperse_tables = Regex.scan(~r/\"[A=Za-z0-9_]*\"/, tables)  |> List.flatten

    IO.puts("FIELDS *** ")
    intersperse_fields = Regex.scan(~r/\"[A=Za-z0-9_]*\"/, fields)  |> IO.inspect |> List.flatten

    {intersperse_fields, intersperse_tables}
  end

  defp query_with_format(query), do: query <> " FORMAT RowBinary"
end

defmodule ClickhouseEcto.HelpersDriver do
  @moduledoc false
  alias ClickhouseEcto.Parsers
  defp parse_table(query) do
    query |> IO.inspect
    # here need to parse query to extract name of table
    # name table should be after INSERT INTO or nothing
    result = Regex.split(~r/INSERT INTO|\(/, query)
    Enum.drop(result, 1) |> hd |> IO.inspect
  end

  @doc false
  def bind_query_params(query, params, base_address) do
    query_parts = String.split(query, "?")

    case length(query_parts) do
      1 ->
        case length(params) do
          0 ->
            query
          _ ->
            raise ArgumentError, "Extra params! Query don't contain '?'"
        end
      len ->
        if (len-1) != length(params) do
          raise ArgumentError, "The number of parameters does not correspond to the number of question marks!"
        end
        table = parse_table(query)
        desc = MachineGun.request!(:post, base_address,
        "DESCRIBE TABLE "<>  table <> " FORMAT JSON", [], %{})

        {type, name} = Parsers.parse_types(desc.body) |> Enum.unzip
        binarize_params(query_parts, params, type)
    end
  end

  def binarize_params(query_parts, params, type) do
    types_params = Enum.zip(params, type)
    binarizated_params = Enum.reduce(types_params, "", fn {val,type}, acc ->
      acc <> Parsers.value_to_binary(val, type) end)
    String.slice(hd(query_parts), 0..-2) <> binarizated_params
  end

  def param_for_query([query_head|query_tail], params) do
  final_query = List.flatten(Enum.zip(query_tail, params)
    |> Enum.map(fn {query, param} ->
      param_as_string(param) <> query end))
  |> Enum.join("")

  final = query_head <> final_query
  end

  @doc false
  def param_as_string(param) when is_list(param) do
    param |> Enum.map(fn(p) -> param_as_string(p) end) |> Enum.join(",")
  end
  def param_as_string(param) when is_integer(param) do
    Integer.to_string(param)
  end
  def param_as_string(param) when is_boolean(param) do
    to_string(param)
  end
  def param_as_string(param) when is_float(param) do
    to_string(param)
  end
  def param_as_string(param) when is_float(param) do
    to_string(param)
  end

  def param_as_string({{year, month, day}, {hour, minute, second, _msecond}}) do
    case Ecto.DateTime.cast({{year, month, day}, {hour, minute, second, 0}}) do
      {:ok, date_time} ->
        "'#{Ecto.DateTime.to_string(date_time)}'"
      {:error} ->
        {:error, %ClickhouseEcto.ErrorDriver{message: :wrong_date_time}}
    end
  end

  def param_as_string({year, month, day}) do
    case Ecto.Date.cast({year, month, day}) do
      {:ok, date} ->
        "'#{Ecto.Date.to_string(date)}'"
      {:error} ->
        {:error, %ClickhouseEcto.ErrorDriver{message: :wrong_date}}
    end
  end
  def param_as_string(param) do
    "'" <> param <> "'"
  end
end

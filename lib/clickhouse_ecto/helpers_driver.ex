defmodule ClickhouseEcto.HelpersDriver do
  @moduledoc false
  alias ClickhouseEcto.Parsers
  defp parse_table_into(query) do
    # query |> IO.inspect
    # here need to parse query to extract name of table
    # name table should be after INSERT INTO or nothing
    result = Regex.split(~r/INSERT INTO|\(/, query) |> IO.inspect
    Enum.drop(result, 1) |> hd # |> IO.inspect
  end


def pmap(collection, function) do
  # Get this process's PID
  me = self
  collection
  |>
  Enum.map(fn (elem) ->
    # For each element in the collection, spawn a process and
    # tell it to:
    # - Run the given function on that element
    # - Call up the parent process
    # - Send the parent its PID and its result
    # Each call to spawn_link returns the child PID immediately.
    spawn_link fn -> (send me, { self, function.(elem) }) end
  end) |>
  # Here we have the complete list of child PIDs. We don't yet know
  # which, if any, have completed their work
  Enum.map(fn (pid) ->
    # For each child PID, in order, block until we receive an
    # answer from that PID and return the answer
    # While we're waiting on something from the first pid, we may
    # get results from others, but we won't "get those out of the
    # mailbox" until we finish with the first one.
    receive do { ^pid, result } -> result end
  end)
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
        table = parse_table_into(query)
        desc = MachineGun.request!(:post, base_address,
        "DESCRIBE TABLE "<>  table <> " FORMAT JSON", [], %{})

        {type, name} = Parsers.parse_types(desc.body) |> Enum.unzip

        # binarize_params(query_parts, params, type)
        binarize_params(query_parts, params, type)
    end
  end

  def binarize_params(query_parts, params, type) do

    # Enum.map(1..300000, fn x -> Parsers.value_to_binary(123, "Int8") end) |> IO.inspect
    chuncked_params = Enum.chunk_every(params, length(type))
    # binarizated_list = pmap(chuncked_params, fn param ->
    # Enum.zip(param, type)
    # |> Enum.map(fn {val, type} ->
    # Parsers.value_to_binary(val, type) end) end)
    binarizated_list = Enum.map(chuncked_params, fn param ->
      Enum.zip(param, type) |> IO.inspect
      |> Enum.map(fn {val, type} ->
      Parsers.value_to_binary(val, type) end) end)

    binarizated_params = :binary.list_to_bin(binarizated_list)
    String.slice(hd(query_parts), 0..-2) <> binarizated_params # |> IO.inspect(limit: 100)
  end

  def param_for_query([query_head|query_tail], params) do
  final_query = List.flatten(Enum.zip(query_tail, params)
    |> Enum.map(fn {query, param} ->
      param_as_string(param) <> query end))
  |> Enum.join("") # |> IO.inspect

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

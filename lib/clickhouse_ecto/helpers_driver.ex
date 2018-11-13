defmodule ClickhouseEcto.HelpersDriver do
  @moduledoc false

  @doc false
  def bind_query_params(query, params) do


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
        param_for_query(query_parts, params)
    end
  end

  def param_for_query([query_head|query_tail], params) do
   final_query = List.flatten(Enum.zip(query_tail, params)|>
   Enum.map(fn {query, param} ->
      param_as_string(param) <> query end))
   |> Enum.join("")

   final = query_head <> final_query


  end

  @doc false
  def param_as_string(param) when is_list(param) do
    param |>
      Enum.map(fn(p) -> param_as_string(p) end) |>
      Enum.join(",")
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
    #param_as_string({{year, month, day}, {0, 0, 0, 0}})
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

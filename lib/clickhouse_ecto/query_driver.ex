defmodule ClickhouseEcto.QueryDriver do
  @moduledoc """
  Query struct returned from a successfully prepared query.
  """

  @type t :: %__MODULE__{
      name:      iodata,
      statement: iodata,
      columns:   [String.t] | nil
  }

  defstruct [:name, :statement, :columns]
end

defimpl DBConnection.Query, for: ClickhouseEcto.QueryDriver do
  #require IEx

  def parse(query, opts) do
    query
  end

  def describe(query, opts) do
    query
  end

#  @spec encode(query :: ClickhouseEcto.Query.t(), params :: [ClickhouseEcto.Type.param()], opts :: Keyword.t()) ::
#          [ClickhouseEcto.Type.param()]
  def encode(query, params, opts) do
#    Enum.map(params, &(ClickhouseEcto.Type.encode(&1, opts)))
    params
  end

#  @spec decode(query :: ClickhouseEcto.Query.t(), result :: ClickhouseEcto.Result.t(), opts :: Keyword.t()) ::
#          ClickhouseEcto.Result.t()
#  def decode(_query, %ClickhouseEcto.Result{rows: rows} = result, opts) when not is_nil(rows) do
#    Map.put(result, :rows, Enum.map(rows, fn row -> Enum.map(row, &(ClickhouseEcto.Type.decode(&1, opts))) end))
#  end
  def decode(_query, result, _opts) do
    case result.command do
      :selected ->
        rows = result.rows
        new_rows = Enum.map(rows, fn el ->
          list1 = Tuple.to_list(el)
          Enum.map(list1, fn el1 ->
            cond do
              is_list(el1) ->
                to_string(el1)
              true ->
                el1
            end
          end)
        end)
        Map.put(result, :rows, new_rows)
      _ ->
        result
    end
  end
end

defimpl String.Chars, for: ClickhouseEcto.QueryDriver do
  def to_string(%ClickhouseEcto.QueryDriver{statement: statement}) do
    IO.iodata_to_binary(statement)
  end
end

defmodule ClickhouseEcto.Type do
  @int_types [:bigint, :integer, :id, :serial]
  @decimal_types [:numeric, :decimal]
  @unix_default_time "1970-01-01"
  @empty_clickhouse_date "0000-00-00"

  def encode(value, :bigint) do
    {:ok, to_string(value)}
  end

  def encode(value, :binary_id) when is_binary(value) do
    Ecto.UUID.load(value)
  end

  def encode(value, :decimal) do
    try do
      {float_value, _} = value |> Decimal.new |> Decimal.to_string |> Float.parse
      {:ok, float_value}
    rescue
      _e in FunctionClauseError ->
        {:ok, value}
    end
  end

  def encode(value, _type) do
    {:ok, value}
  end

  def decode(value, type)
  when type in @int_types and is_binary(value) do
    case Integer.parse(value) do
      {int, _}  -> {:ok, int}
      :error    -> {:error, "Not an integer id"}
    end
  end

  def decode(value, type)
  when type in [:float] do
    tmp = if is_binary(value), do: value, else: to_string(value)
    case Float.parse(tmp) do
      {float, _}  -> {:ok, float}
      :error    -> {:error, "Not an float value"}
    end
  end

  def decode(value, type)
  when type in @decimal_types do
    {:ok, Decimal.new(value)}
  end

  def decode(value, :uuid) do
    Ecto.UUID.dump(value)
  end

  def decode({date, {h, m, s}}, type)
  when type in [:utc_datetime, :naive_datetime] do
    {:ok, {date, {h, m, s, 0}}}
  end

  def decode(value, type)
  when type in [:date] and is_binary(value) do
    case value do
      @empty_clickhouse_date ->
        Ecto.Date.cast!(@unix_default_time)
      val ->
        Ecto.Date.cast!(val)
    end |> Ecto.Date.dump
  end

  def decode(value, _type) do
    {:ok, value}
  end

end

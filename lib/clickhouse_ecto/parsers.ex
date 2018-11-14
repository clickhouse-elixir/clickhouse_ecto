defmodule ClickhouseEcto.Parsers do

  def row_binary_parser(binary_data, types) do
    IO.puts("row_binary_parser")
    list_of_types = parse_types(types)
    Enum.map(list_of_types, fn x ->
      cond do
      x == "String" -> binary_to_string(binary_data)
      x == "Int8" -> binary_to_int8(binary_data)
      true -> "Type is not exist"
      end
    end)
    # binary_data |> IO.inspect
  end

  def parse_types(types) do
    IO.puts("parse_types")
    case Poison.decode(types) do
      {:ok, %{"data" => data}} ->
        columns = data |> Enum.map(fn(%{"type" => type}) -> type end)
    end
  end

  def binary_to_int8(binary_data) do
    IO.puts("-> to_Int8")
    <<x::little-signed-integer-size(8)>> = binary_data
    x
  end

  def binary_to_int16(binary_data) do
    IO.puts("-> to_Int16")
    <<x::little-signed-integer-size(16)>> = binary_data
    x
  end

  def binary_to_int32(binary_data) do
    IO.puts("-> to_Int32")
    <<x::little-signed-integer-size(32)>> = <<binary_data::binary>>
    x
  end

  def binary_to_int64(binary_data) do
    IO.puts("-> to_Int64")
    <<x::little-signed-integer-size(64)>> = <<binary_data::binary>>
    x
  end

  def binary_to_uint8(binary_data) do
    IO.puts("-> to_UInt8")
    <<x::little-unsigned-integer-size(8)>> = binary_data
    x
  end

  def binary_to_uint16(binary_data) do
    IO.puts("-> to_UInt16")
    <<x::little-unsigned-integer-size(16)>> = binary_data
    x
  end

  def binary_to_uint32(binary_data) do
    IO.puts("-> to_UInt32")
    <<x::little-unsigned-integer-size(32)>> = binary_data
    x
  end

  def binary_to_uint64(binary_data) do
    IO.puts("-> to_UInt64")
    <<x::little-unsigned-integer-size(64)>> = binary_data
    x
  end

  def binary_to_float32(binary_data) do
    IO.puts("-> to_Float32")
    <<x::little-float-size(32)>> = binary_data
  end

  def binary_to_float64(binary_data) do
    IO.puts("-> to_Float64")
    <<x::little-float-size(64)>> = binary_data
  end

  def binary_to_string(binary_data) do
    IO.puts("-> to_String")

    binary_list = :binary.bin_to_list(binary_data)
    size = binary_list |> hd
    string = Enum.take(:binary.bin_to_list(binary_data)
      |> tl, size) |> IO.iodata_to_binary()
    IO.inspect(string)
    {string, Enum.drop(binary_list, size + 1)}
  end

  def binary_to_date(binary_data) do
    IO.puts("-> to_Date")
  end

  def binary_to_datetime(binary_data) do
    IO.puts("-> to_DateTime")
  end

  def binary_to_decimals(binary_data) do
    IO.puts("-> to_DateTime")
  end

end

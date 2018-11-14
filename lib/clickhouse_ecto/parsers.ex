defmodule ClickhouseEcto.Parsers do

  def row_binary_parser(binary_data, types) do
    IO.puts("row_binary_parser")
    {list_of_types,_} = parse_types(types) |> Enum.unzip
    binary_list = :binary.bin_to_list(binary_data)
    binary_data |> IO.inspect(limit: 100)
    result = convert_types(list_of_types, binary_list, 0) |> IO.inspect
  end

  def parse_types(types) do
    IO.puts("parse_types")
    case Poison.decode(types) do
      {:ok, %{"data" => data}} ->
        columns = data |> Enum.map(fn(%{"type" => type, "name" => name}) -> {type, name} end)
    end
  end

  # convert binary data to types on the rows
  def convert_types(list_of_types, binary_list, position) when length(binary_list) == 0 do
    []
  end

  def convert_types(list_of_types, binary_list, position) do
    IO.puts("convert_types")
    binary_list |> IO.inspect

    result = convert_binary(list_of_types, binary_list, position) |> IO.inspect
    crunch = List.last(result)
    cr_res = Enum.drop(result, -1)
    IO.puts("______________________________________")
    [cr_res | convert_types(list_of_types, Enum.drop(binary_list, crunch), crunch)]
  end

  # convert binary data to types on the row
  def convert_binary(list_of_types, binary_list, res \\ 0)

  def convert_binary(list_of_types, binary_list, res) when length(list_of_types) == 0 do
    [res]
  end

  def convert_binary(list_of_types, binary_list, res) do
    IO.puts("convert_binary")
    list_of_types |> IO.inspect
    type = hd(list_of_types)
    {result, position} = parse_binary(binary_list, type)
    res = res + position
    IO.puts("******************")
    res |> IO.inspect

    [result | convert_binary(tl(list_of_types), Enum.drop(binary_list, position), res) ]
  end

  def parse_binary(binary_list, type) when type == "Int8" do
    IO.puts("-> to_Int8")
    size = 1
    sub_list = Enum.take(binary_list, size) |> :binary.list_to_bin

    <<result::little-signed-integer-size(8)>> = sub_list
    IO.puts("---> " <> Integer.to_string(result))
    {result, size}
  end

  def parse_binary(binary_list, type) when type == "Int16" do
    IO.puts("-> to_Int16")
    size = 2
    sub_list = Enum.take(binary_list, size) |> :binary.list_to_bin

    <<result::little-signed-integer-size(16)>> = sub_list
    IO.puts("---> " <> Integer.to_string(result))
    {result, size}
  end

  def parse_binary(binary_list, type) when type == "Int32" do
    IO.puts("-> to_Int32")
    size = 4
    sub_list = Enum.take(binary_list, size) |> :binary.list_to_bin

    <<result::little-signed-integer-size(32)>> = sub_list
    IO.puts("---> " <> Integer.to_string(result))
    {result, size}
  end

  def parse_binary(binary_list, type) when type == "Int64" do
    IO.puts("-> to_Int64")
    size = 8
    sub_list = Enum.take(binary_list, size) |> :binary.list_to_bin

    <<result::little-signed-integer-size(64)>> = sub_list
    IO.puts("---> " <> Integer.to_string(result))
    {result, size}
  end

  def parse_binary(binary_list, type) when type == "UInt8" do
    IO.puts("-> to_UInt8")
    size = 1
    sub_list = Enum.take(binary_list, size) |> :binary.list_to_bin

    <<result::little-unsigned-integer-size(8)>> = sub_list
    IO.puts("---> " <> Integer.to_string(result))
    {result, size}
  end

  def parse_binary(binary_list, type) when type == "UInt16" do
    IO.puts("-> to_UInt16")
    size = 2
    sub_list = Enum.take(binary_list, size) |> :binary.list_to_bin

    <<result::little-unsigned-integer-size(16)>> = sub_list
    IO.puts("---> " <> Integer.to_string(result))
    {result, size}
  end

  def parse_binary(binary_list, type) when type == "UInt32" do
    IO.puts("-> to_UInt32")
    size = 4
    sub_list = Enum.take(binary_list, size) |> :binary.list_to_bin

    <<result::little-unsigned-integer-size(32)>> = sub_list
    IO.puts("---> " <> Integer.to_string(result))
    {result, size}
  end

  def parse_binary(binary_list, type) when type == "UInt64" do
    IO.puts("-> to_UInt64")
    size = 8
    sub_list = Enum.take(binary_list, size) |> :binary.list_to_bin

    <<result::little-unsigned-integer-size(64)>> = sub_list
    IO.puts("---> " <> Integer.to_string(result))
    {result, size}
  end

  def parse_binary(binary_list, type) when type == "Float32" do
    IO.puts("-> to_Float32")
    size = 4
    sub_list = Enum.take(binary_list, size) |> :binary.list_to_bin

    <<result::little-float-size(32)>> = sub_list
    # Float.round(result, )
    IO.puts("---> " <> Float.to_string(result))
    {result, size}
  end

  def parse_binary(binary_list, type) when type == "Float64" do
    IO.puts("-> to_Float64")
    size = 8
    sub_list = Enum.take(binary_list, size) |> :binary.list_to_bin

    <<result::little-float-size(64)>> = sub_list
    IO.puts("---> " <> Float.to_string(result))
    {result, size}
  end

  def parse_binary(binary_list, type) when type == "String" do
    IO.puts("-> to_String")
    size = binary_list |> hd
    result = Enum.take(binary_list |> tl, size) |> IO.iodata_to_binary()
    IO.puts("---> " <> result)
    {result, size + 1}
  end

  def parse_binary(binary_list, type) when type == "Date" do
    IO.puts("-> to_Date")
    size = 2
    sub_list = Enum.take(binary_list, size) |> :binary.list_to_bin

    <<x::little-integer-size(16)>> = sub_list
    result = Date.to_string(Date.add(~D[1970-01-01], x))
    IO.puts("---> " <> result)
    {result, size}
  end

  def parse_binary(binary_list, type) when type == "DateTime" do
    IO.puts("-> to_DateTime")
    size = 4
    sub_list = Enum.take(binary_list, size) |> :binary.list_to_bin

    <<x::little-integer-size(32)>> = sub_list
    result = DateTime.from_unix!(x)
      |> DateTime.to_string
      |> String.replace("Z", "")

    IO.puts("---> " <> result)
    {result, size}
  end


  # def list_to_binary(query_list, types) do
  #   IO.puts("list_to_binary")
  #   list_of_types = parse_types(types)
  #   convert_to_binary(query_list, types)
  # end

  # def convert_to_binary(list, types) do
  #   IO.puts("convert_to_binary")
  #   type = hd(list_of_types)
  #   result = parse_binary(binary_list, type)

  #   [result | convert_binary(tl(list_of_types), Enum.drop(binary_list, position), res) ]
  # end

  # type to binary
  def parse_type(list, type) when type == "Int8" do
    IO.puts("-> Int8_to_binary")
    elem = hd(list)
    result = <<elem::little-signed-integer-size(8)>>
    {result, 2}
  end

  def parse_type(list, type) when type == "Int16" do
    IO.puts("-> Int16_to_binary")
    elem = hd(list)
    result = <<elem::little-signed-integer-size(16)>>
    {result, 2}
  end

  def parse_type(list, type) when type == "Int32" do
    IO.puts("-> Int32_to_binary")
    elem = hd(list)
    result = <<elem::little-signed-integer-size(32)>>
    {result, 2}
  end

  def parse_type(list, type) when type == "Int64" do
    IO.puts("-> Int64_to_binary")
    elem = hd(list)
    result = <<elem::little-signed-integer-size(64)>>
    {result, 2}
  end

  def parse_type(list, type) when type == "UInt8" do
    IO.puts("-> UInt8_to_binary")
    elem = hd(list)
    result = <<elem::little-unsigned-integer-size(8)>>
    {result, 2}
  end

  def parse_type(list, type) when type == "UInt16" do
    IO.puts("-> UInt16_to_binary")
    elem = hd(list)
    result = <<elem::little-unsigned-integer-size(16)>>
    {result, 2}
  end

  def parse_type(list, type) when type == "UInt32" do
    IO.puts("-> UInt32_to_binary")
    elem = hd(list)
    result = <<elem::little-unsigned-integer-size(32)>>
    {result, 2}
  end

  def parse_type(list, type) when type == "UInt64" do
    IO.puts("-> UInt64_to_binary")
    elem = hd(list)
    result = <<elem::little-unsigned-integer-size(64)>>
    {result, 2}
  end

  def parse_type(list, type) when type == "Float32" do
    IO.puts("-> Float32_to_binary")
    elem = hd(list)
    result = <<elem::little-float-size(32)>>
    {result, 2}
  end

  def parse_type(list, type) when type == "Float64" do
    IO.puts("-> Float64_to_binary")
    size = 8
    elem = hd(list)
    result = <<elem::little-float-size(64)>>
    {result, 2}
  end

  def parse_type(list, type) when type == "String" do
    IO.puts("-> String_to_binary")
    elem = hd(list)
    size = String.length(elem)
    result = <<size>> <> elem
    {result, size + 1}
  end

end

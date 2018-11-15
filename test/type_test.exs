defmodule ClickhouseEcto.TypeTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias ClickhouseEcto.Result
  alias ClickhouseEcto.Parsers

  setup_all do
    {:ok, pid} = ClickhouseEcto.Driver.start_link([])
    ClickhouseEcto.Driver.query!(pid, "DROP DATABASE IF EXISTS test_type", [])
    {:ok, _, _} = ClickhouseEcto.Driver.query(pid, "CREATE DATABASE test_type", [])
    {:ok, _, %Result{}}
           = ClickhouseEcto.Driver.query(pid, "CREATE TABLE IF NOT EXISTS test_type.test (a String, b Int8, c Int16, d Int32,
              e Int64, f UInt8, g UInt16, h UInt32, i UInt64, j Float32, k Float64, l Date, m DateTime) ENGINE = Memory", [])
    list = ["\'qwerty\'", -25, -1502, -35000,
      -2147483649, 25, 1502, 70000, 4294967298, -42.981109619140625, 42.98, "\'2018-11-14\'", "\'2015-09-13 22:27:15\'"]
    sub_list = Enum.join(list, ", ")

    {:ok, _, %Result{command: :updated, num_rows: 1}}
           = ClickhouseEcto.Driver.query(pid, ["INSERT INTO test_type.test VALUES (" <> sub_list <> ")"], [])
    {:ok, [list: list]}
  end

  test "parse types", %{list: list} do

    types = MachineGun.request!(:post, "http://localhost:8123",
      "DESCRIBE TABLE test_type.test FORMAT JSON", [], %{}).body

    {list_of_types, name} = Parsers.parse_types(types) |> Enum.unzip

    binary_data = MachineGun.request!(:post, "http://localhost:8123",
      "SELECT * FROM test_type.test FORMAT RowBinary", [], %{}).body

    assert list |> Enum.join(", ") |> String.replace("\'", "") =~
    Parsers.row_binary_parser(binary_data, list_of_types) |>  hd |> Tuple.to_list|> Enum.join(", ")

    # assert ["String", "String"] = Parsers.parse_types(types)

    # Parsers.row_binary_parser(binary_data, types)
  end

  test "convert types" do
    # int8
    int8_test = -25
    assert int8_test = Parsers.parse_binary(<<int8_test::little-signed-integer-size(8)>> |> :binary.bin_to_list, "Int8")
    # int16
    int16_test = -1502
    assert int16_test = Parsers.parse_binary(<<int16_test::little-signed-integer-size(16)>> |> :binary.bin_to_list, "Int16")
    # int32
    int32_test = -35000
    assert int32_test = Parsers.parse_binary(<<int32_test::little-signed-integer-size(32)>> |> :binary.bin_to_list, "Int32")
    # int64
    int64_test = -2147483649
    assert int64_test = Parsers.parse_binary(<<int64_test::little-signed-integer-size(64)>> |> :binary.bin_to_list, "Int64")
    # uint8
    uint8_test = 25
    assert uint8_test = Parsers.parse_binary(<<uint8_test::little-signed-integer-size(8)>> |> :binary.bin_to_list, "UInt8")
    # uint16
    uint16_test = 1502
    assert uint16_test = Parsers.parse_binary(<<uint16_test::little-signed-integer-size(16)>> |> :binary.bin_to_list,  "UInt16")
    # uint32
    uint32_test = 70000
    assert uint32_test = Parsers.parse_binary(<<uint32_test::little-signed-integer-size(32)>> |> :binary.bin_to_list, "UInt32")
    # uint64
    uint64_test = 4294967298
    assert uint64_test = Parsers.parse_binary(<<uint64_test::little-signed-integer-size(64)>> |> :binary.bin_to_list, "UInt64")
    # float32
    float32_test = -42.98
    assert float32_test = Parsers.parse_binary(<<float32_test::little-float-size(32)>> |> :binary.bin_to_list, "Float32")
    # float64
    float64_test = 42.98
    assert float64_test = Parsers.parse_binary(<<float64_test::little-float-size(64)>> |> :binary.bin_to_list, "Float64")
    # string
    string_test = "abrakadabra"
    assert float64_test = Parsers.parse_binary(<<11>> <> string_test <> <<0>> |> :binary.bin_to_list, "String")
    # date
    date = 17849
    assert date = Parsers.parse_binary(<<date::little-signed-integer-size(16)>> |> :binary.bin_to_list, "Date")
    # datetime
    datetime = 1442183235
    assert datetime = Parsers.parse_binary(<<datetime::little-signed-integer-size(32)>> |> :binary.bin_to_list, "DateTime")
  end

end

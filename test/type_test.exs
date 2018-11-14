defmodule ClickhouseEcto.TypeTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias ClickhouseEcto.Result
  alias ClickhouseEcto.Parsers

  test "parse types" do
    # assert {:ok, _, %Result{command: :updated, num_rows: 1}}
    # = ClickhouseEcto.Driver.query(pid, ["SELECT c FROM test_type.test FORMAT RowBinary"], [])
    types = MachineGun.request!(:post, "http://localhost:8123",
      "DESCRIBE TABLE test_type.test FORMAT JSON", [], %{}).body

    assert ["UInt32", "UInt64", "Int8"] = Parsers.parse_types(types)

    binary_data = MachineGun.request!(:post, "http://localhost:8123",
      "SELECT * FROM test_type.test FORMAT RowBinary", [], %{}).body

    # Parsers.row_binary_parser(binary_data, types)
  end

  test "convert types" do
    # int8
    int8_test = -25
    assert int8_test = Parsers.binary_to_int8(<<int8_test::little-signed-integer-size(8)>>)
    # int16
    int16_test = -1502
    assert int16_test = Parsers.binary_to_int16(<<int16_test::little-signed-integer-size(16)>>)
    # int32
    int32_test = -35000
    assert int32_test = Parsers.binary_to_int32(<<int32_test::little-signed-integer-size(32)>>)
    # int64
    int64_test = -2147483649
    assert int64_test = Parsers.binary_to_int64(<<int64_test::little-signed-integer-size(64)>>)
    # uint8
    uint8_test = 25
    assert uint8_test = Parsers.binary_to_uint8(<<uint8_test::little-signed-integer-size(8)>>)
    # uint16
    uint16_test = 1502
    assert uint16_test = Parsers.binary_to_uint16(<<uint16_test::little-signed-integer-size(16)>>)
    # uint32
    uint32_test = 70000
    assert uint32_test = Parsers.binary_to_uint32(<<uint32_test::little-signed-integer-size(32)>>)
    # uint64
    uint64_test = 4294967298
    assert uint64_test = Parsers.binary_to_uint64(<<uint64_test::little-signed-integer-size(64)>>)
    # float32
    float32_test = -42.98
    assert float32_test = Parsers.binary_to_float32(<<float32_test::little-float-size(32)>>)
    # float64
    float64_test = 42.98
    assert float64_test = Parsers.binary_to_float64(<<float64_test::little-float-size(64)>>)
    # string
    string_test = "abrakadabra"
    assert float64_test = Parsers.binary_to_string(<<11>> <> string_test <> <<0>>)
  end

end

defmodule ClickhouseEcto.TypeTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias ClickhouseEcto.Result
  setup_all do
    {:ok, pid} = ClickhouseEcto.Driver.start_link([])
    {:ok, [pid: pid]}
  end
  test "simple select", %{pid: pid} do
    # assert {:ok, _, %Result{command: :updated, num_rows: 1}}
    # = ClickhouseEcto.Driver.query(pid, ["SELECT c FROM test_type.test FORMAT RowBinary"], [])
    types = MachineGun.request!(:post, "http://localhost:8123",
      "DESCRIBE TABLE test_type.test FORMAT JSON", [], %{}).body
    assert ["String", "Int8", "Int16"] = ClickhouseEcto.Parsers.parse_types(types)

    binary_data = MachineGun.request!(:post, "http://localhost:8123",
      "SELECT * FROM test_type.test FORMAT RowBinary", [], %{}).body
    ClickhouseEcto.Parsers.row_binary_parser(binary_data, types)
  end
end

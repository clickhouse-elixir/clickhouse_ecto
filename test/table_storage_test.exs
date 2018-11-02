defmodule ClickhouseEcto.TableStorageTest do
  use ExUnit.Case, async: true

  alias ClickhouseEcto.Result

  setup do
    {:ok, pid} = ClickhouseEcto.Driver.start_link([])
    ClickhouseEcto.Driver.query(pid, "CREATE DATABASE table_storage_test", [])
    {:ok, [pid: pid]}
  end

  test "can create and drop table", %{pid: pid} do
    assert {:ok, _, %Result{}}
           = ClickhouseEcto.Driver.query(pid, "CREATE TABLE table_storage_test.can_create_drop(id Int32) ENGINE = Memory", [])
    assert {:ok, _, %Result{}}
           = ClickhouseEcto.Driver.query(pid, "DROP TABLE table_storage_test.can_create_drop", [])
  end

  test "returns correct error when dropping table that doesn't exist", %{pid: pid} do
    assert {:error, %{code: :base_table_or_view_not_found}}
           = ClickhouseEcto.Driver.query(pid, "DROP TABLE table_storage_test.not_exist", [])
  end

  test "returns correct error when creating a table that already exists", %{pid: pid} do
    ClickhouseEcto.Driver.query(pid, "DROP TABLE table_storage_test.table_already_exists", [])

    sql = "CREATE TABLE table_storage_test.table_already_exists(id Int32) ENGINE = Memory"
    assert {:ok, _, %Result{}} = ClickhouseEcto.Driver.query(pid, sql, [])
    assert {:error, %{code: :table_already_exists}} = ClickhouseEcto.Driver.query(pid, sql, [])
  end
end

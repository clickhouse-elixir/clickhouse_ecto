defmodule ClickhouseEcto.StorageTest do
  use ExUnit.Case, async: true

  alias ClickhouseEcto.Result

  setup do
    {:ok, pid} = ClickhouseEcto.Driver.start_link([])
    ClickhouseEcto.Driver.query(pid, "DROP DATABASE storage_test", [])
    {:ok, [pid: pid]}
  end

  test "can create and drop database", %{pid: pid} do
    assert {:ok, _, %Result{}} = ClickhouseEcto.Driver.query(pid, "CREATE DATABASE storage_test", [])
    assert {:ok, _, %Result{}} = ClickhouseEcto.Driver.query(pid, "DROP DATABASE storage_test", [])
  end

  test "returns correct error when dropping database that doesn't exist", %{pid: pid} do
    assert {:error, %{code: :database_does_not_exists}} = ClickhouseEcto.Driver.query(pid, "DROP DATABASE storage_test", [])
  end

  test "returns correct error when creating a database that already exists", %{pid: pid} do
    assert {:ok, _, %Result{}} = ClickhouseEcto.Driver.query(pid, "CREATE DATABASE storage_test", [])
    assert {:error, %{code: :database_already_exists}} = ClickhouseEcto.Driver.query(pid, "CREATE DATABASE storage_test", [])
  end
end

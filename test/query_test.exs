defmodule ClickhouseEcto.QueryTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias ClickhouseEcto.Result

  setup_all do
    {:ok, pid} = ClickhouseEcto.Driver.start_link([])
    ClickhouseEcto.Driver.query!(pid, "DROP DATABASE IF EXISTS query_test", [])
    {:ok, _, _} = ClickhouseEcto.Driver.query(pid, "CREATE DATABASE query_test", [])

    {:ok, [pid: pid]}
  end

  test "simple select", %{pid: pid} do
    assert {:ok, _, %Result{}}
           = ClickhouseEcto.Driver.query(pid, "CREATE TABLE IF NOT EXISTS query_test.simple_select (name String) ENGINE = Memory", [])

    assert {:ok, _, %Result{command: :updated, num_rows: 1}}
           = ClickhouseEcto.Driver.query(pid, ["INSERT INTO query_test.simple_select VALUES ('qwerty')"], [])

    assert {:ok, _, %Result{command: :selected, columns: ["name"], num_rows: 1, rows: [["qwerty"]]}}
           = ClickhouseEcto.Driver.query(pid, "SELECT * FROM query_test.simple_select", [])
  end

  test "parametrized queries", %{pid: pid} do
    assert {:ok, _, %Result{}}
           = ClickhouseEcto.Driver.query(pid, "CREATE TABLE query_test.parametrized_query(id Int32, name String) ENGINE = Memory", [])

    assert {:ok, _, %Result{command: :updated, num_rows: 1}}
           = ClickhouseEcto.Driver.query(pid, ["INSERT INTO query_test.parametrized_query VALUES (?, ?)"], [1, "abyrvalg"])

    assert {:ok, _, %Result{command: :selected, columns: ["id", "name"], num_rows: 1, rows: [[1, "abyrvalg"]]}}
           = ClickhouseEcto.Driver.query(pid, "SELECT * FROM query_test.parametrized_query", [])
  end
end

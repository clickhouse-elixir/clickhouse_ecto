defmodule ClickhouseEcto.InsertRowbinaryTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias ClickhouseEcto.Result
  alias ClickhouseEcto.Parsers

  setup_all do
    {:ok, pid} = ClickhouseEcto.Driver.start_link([])
    ClickhouseEcto.Driver.query!(pid, "DROP DATABASE IF EXISTS rowbinary", [])
    {:ok, _, _} = ClickhouseEcto.Driver.query(pid, "CREATE DATABASE rowbinary", [])
    {:ok, _, %Result{}}
           = ClickhouseEcto.Driver.query(pid, "create table if not exists rowbinary.test (a UInt32, b String, c Int8) Engine=Memory", [])
    list = ["\'qwerty\'", -25, -1502, -35000,
      -2147483649, 25, 1502, 70000, 4294967298, -42.981109619140625, 42.98, "\'2018-11-14\'", "\'2015-09-13 22:27:15\'"]
    sub_list = Enum.join(list, ", ")


    {:ok, [list: list, pid: pid]}
  end

  # test "insert into rowbinary", %{list: list, pid: pid} do
  #   value = <<-25::little-signed-integer-size(8)>>
  #   value2 = <<25::little-unsigned-integer-size(32)>>
  #   query_string = "INSERT INTO rowbinary.test FORMAT RowBinary\n#{value2}" <> <<6>> <> "qwerty" <> "#{value}#{value2}" <> <<6>> <> "qwerty" <> "#{value}"
  #   IO.inspect(query_string)
  #     {:ok, _, %Result{command: :updated, num_rows: 1}}
  #   = ClickhouseEcto.Driver.query(pid, [query_string], [])

  # end

  test "insert into rowbinary", %{list: list, pid: pid} do
    insert_query = ClickhouseEcto.Query.insert(
      "rowbinary", "test", [:a, :b, :c], [[:a, :b, :c]], {:raise, [], []}, []) |> IO.inspect

      state = %ClickhouseEcto.Protocol{
        base_address: "http://localhost:8123/",
        conn_opts: [
          scheme: :http,
          hostname: "localhost",
          port: 8123,
          database: "default",
          username: nil,
          password: nil,
          timeout: 60000
        ]
      }

      ClickhouseEcto.Protocol.do_query(%ClickhouseEcto.QueryDriver{name: "", statement: insert_query, columns: [:a, :b, :c]},
      [123123, "adsaas", 8], [], state, :post)

    # query_string = "INSERT INTO rowbinary.test FORMAT RowBinary\n#{value2}" <> <<6>> <> "qwerty" <> "#{value}#{value2}" <> <<6>> <> "qwerty" <> "#{value}"
    # IO.inspect(query_string)
    #   {:ok, _, %Result{command: :updated, num_rows: 1}}
    # = ClickhouseEcto.Driver.query(pid, [query_string], [])

  end


end

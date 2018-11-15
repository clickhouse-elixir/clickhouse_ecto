defmodule ClickhouseEcto.PingTest do
  use ExUnit.Case
  alias ClickhouseEcto.Protocol

  alias ClickhouseEcto.HTTPClient
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
  base_address= "http://localhost:8123/"
  scheme= :http
  hostname= "localhost"
  port=8123
  database="default"
  username= nil
  password= nil
  timeout= 60000
  assert HTTPClient.send("", base_address, timeout, username, password, database, :get) == {:updated, 1}
  assert MachineGun.get!("http://localhost:8123?query=SELECT%201").body =~ "1"
  {:ok, new_state} = Protocol.ping(state)
  assert  state == new_state


end

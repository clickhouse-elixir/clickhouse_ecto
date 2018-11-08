defmodule ClickhouseEcto.MachineGunTest do

  use ExUnit.Case, async: true


  test "get request" do



    assert MachineGun.get!("http://localhost:8123?query=SELECT%201").body =~ "1"

    assert MachineGun.request(:get, "http://localhost:8123", "", [], %{})

    assert MachineGun.request(:post, "http://localhost:8123", "SELECT 1", [], %{})

    # opts = %{hackney: Map.merge(basic_auth: {"test_auth", "1234"}, timeout: 30, recv_timeout: 23)}
    opts = %{hackney: [basic_auth: {"test_auth", "1234"}], timeout: 30, recv_timeout: 23}

    opts_new = Map.merge(opts, %{params: %{database: "example_app"}})
    assert MachineGun.request!(:post, "http://localhost:8123", "SELECT 1", [], opts_new).body =~ "1"


  end
end

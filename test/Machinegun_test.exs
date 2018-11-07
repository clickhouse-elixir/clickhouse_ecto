defmodule ClickhouseEcto.MachineGunTest do

  use ExUnit.Case, async: true


  test "get request" do



    assert MachineGun.get!("http://localhost:8123?query=SELECT%201").body =~ "1"


  end
end

defmodule ClickhouseEcto.CreateTablesTest do
  use ExUnit.Case

  @alphabet Enum.concat([?A..?Z, ?a..?z])

  def randstring(count) do
    Stream.repeatedly(&random_char_from_alphabet/0)
    |> Enum.take(count)
    |> List.to_string()
  end

  def random_char_from_alphabet() do
    Enum.random(@alphabet)
  end

  test "generate random string" do
    # randstring(10) |> IO.inspect
  end


end

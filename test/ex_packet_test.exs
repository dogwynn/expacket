defmodule ExPacketTest do
  use ExUnit.Case
  doctest ExPacket

  test "greets the world" do
    assert ExPacket.hello() == :world
  end
end

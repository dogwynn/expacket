defmodule ExPacket.EthernetTest do
    use ExUnit.Case
    doctest ExPacket.Ethernet

    test "can " do
      assert ExPacket.hello() == :world
    end
  end

defmodule ExPacket.IP do
    def ntoa(<< a::8, b::8, c::8, d::8 >>) do
        :inet.ntoa({a, b, c, d})
        |> List.to_string
    end
    def ntoa(n) when is_integer(n) and n >= 0 and n < 4294967296 do
        ntoa(<< n::32 >>)
    end
end
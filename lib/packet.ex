defmodule ExPacket.Packet do
    require Logger

    @spec new(integer) :: binary
    def new(bytes) do
        bits = bytes * 8
        << 0::size(bits) >>
    end

    @spec index(binary, integer) :: integer
    def index(packet, i) when i < 0 do
        length = byte_size(packet)
        index(packet, length + i)
    end
    def index(_packet, i), do: i

    @spec adjust(binary, integer, integer) :: binary
    def adjust(packet, i, size) do
        case (index(packet, i) + size - byte_size(packet)) do
            diff when diff > 0 -> packet <> << 0::(diff * 8) >>
            _ -> packet
        end
    end

    @spec replace(binary, integer, binary) :: binary
    def replace(packet, i, value) do
        new_i = index(packet, i)

        packet = packet
        |> adjust(i, byte_size(value))

        new_s = byte_size(packet)
        value_s = byte_size(value)
        value_i = new_i

        head = binary_part(packet, 0, new_i)
        tail = binary_part(
            packet, value_i + value_s, new_s - (value_i + value_s)
        )

        Logger.debug "#{new_s} #{value_i} #{value_s}"
        head <> value <> tail
    end

    @spec set_int(binary, integer, integer, integer, atom) :: binary
    def set_int(packet, i, value, bits, order \\ :big) do
        value = case order do
            :little -> << value::little-size(bits) >>
            :big -> << value::big-size(bits) >>
            :native -> << value::native-size(bits) >>
        end
        packet
        |> replace(i, value)
    end

    @spec get_int(binary, integer, integer, atom) :: integer
    def get_int(packet, i, bits, order \\ :big) do
        head_bits = index(packet, i) * 8
        case order do
            :little ->
                << _head::size(head_bits),
                value::little-size(bits),
                _rest::binary >> = packet
                value
            :big ->
                << _head::size(head_bits),
                value::big-size(bits),
                _rest::binary >> = packet
                value
            :native ->
                << _head::size(head_bits),
                value::native-size(bits),
                _rest::binary >> = packet
                value
        end
    end

    @spec set_byte(binary, integer, integer) :: binary
    def set_byte(packet, i, value) do
        set_int(packet, i, value, 8)
    end
    @spec get_byte(binary, integer) :: integer
    def get_byte(packet, i) do
        packet |> :binary.at(i)
    end

    @spec set_word(binary, integer, integer, atom) :: binary
    def set_word(packet, i, value, order \\ :big) do
        set_int(packet, i, value, 16, order)
    end
    @spec get_word(binary, integer, atom) :: integer
    def get_word(packet, i, order \\ :big) do
        get_int(packet, i, 16, order)
    end

    @spec set_long(binary, integer, integer, atom) :: binary
    def set_long(packet, i, value, order \\ :big) do
        set_int(packet, i, value, 32, order)
    end
    @spec get_long(binary, integer, atom) :: integer
    def get_long(packet, i, order \\ :big) do
        get_int(packet, i, 32, order)
    end

    @spec set_long_long(binary, integer, integer, atom) :: binary
    def set_long_long(packet, i, value, order \\ :big) do
        set_int(packet, i, value, 64, order)
    end
    @spec get_long_long(binary, integer, atom) :: integer
    def get_long_long(packet, i, order \\ :big) do
        get_int(packet, i, 64, order)
    end

    @spec set_ip(binary, integer, String.t) :: binary
    def set_ip(packet, i, ip) when is_binary(ip) do
        set_ip(packet, i, String.to_charlist(ip))
    end
    @spec set_ip(binary, integer, list) :: binary
    def set_ip(packet, i, ip) when is_list(ip) do
        case :inet.parse_address(ip) do
            {:ok, {a, b, c, d}} ->
                packet |> replace(i, << a, b, c, d >>)
            error ->
                Logger.error(
                    "Could not parse given IP: #{ip} --> #{inspect(error)}"
                )
                packet
        end
    end

    @spec get_ip(binary, integer) :: String.t
    def get_ip(packet, i) do
        packet
        |> binary_part(index(packet, i), 4)
        |> ExPacket.IP.ntoa
    end

    use Bitwise
    @spec checksum(binary, integer) :: non_neg_integer
    def checksum(<<>>, sum) do
        sum
        |> Bitwise.band(0xffff)
        |> Bitwise.bxor(0xffff)
    end
    def checksum(<< a >>, sum), do: checksum(<<>>, a * 256 + sum)
    def checksum(<< a, b, rest::binary>>, sum) do
        checksum(rest, sum + a * 256 + b)
    end
    @spec checksum(binary) :: non_neg_integer
    def checksum(bytes), do: checksum(bytes, 0)
end

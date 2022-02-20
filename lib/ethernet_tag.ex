defmodule ExPacket.EthernetTag do
  alias ExPacket.Packet, as: Packet
  use Bitwise
  require Logger

  @spec new(integer) :: binary
  def new(value \\ 0x81000000) do
    Packet.new(4)
    |> Packet.set_long(0, value)
  end

  @spec ether_type :: MapSet.t
  def ether_type, do: MapSet.new([
    << 0x81, 0x00 >>, # VLAN-tagged frame (IEEE 802.1Q)
    << 0x88, 0xa8 >>, # Service VLAN tag identifier (S-Tag)
    << 0x91, 0x00 >>  # VLAN-tagged frame (IEEE 802.1Q) double
  ])

  @spec count(binary, integer) :: integer
  def count(<< a, b, rest::binary >>, n) do
    if MapSet.member?(ether_type(), << a, b >>) do
      count(rest, n + 1)
    else
      n
    end
  end
  @spec count(binary) :: integer
  def count(packet) do
    << _pre::binary-size(12), tags::binary >> = packet
    count(tags, 0)
  end

  @spec get_tag(binary, integer) :: binary
  def get_tag(packet, i) do
    index = 12 + 4 * i
    if index >= byte_size(packet) - 4 do
      Logger.error(
        "Bad tag index (#{i}): max index is #{count(packet) - 1}"
      )
    end
    << _::binary-size(index),
       tag::binary-size(4),
       _::binary >> = packet
    tag
  end
  @spec set_tag(binary, integer, binary) :: binary
  def set_tag(packet, i, tag) do
    index = 12 + 4 * i
    packet
    |> Packet.replace(index, tag)
  end

  @doc """
  Tag Protocol Identifier
  """
  @spec tpid(binary) :: integer
  def tpid(tag) do
    tag
    |> Packet.get_word(0)
  end
  @spec tpid(binary, integer) :: integer
  def tpid(packet, tag_i) do
    packet
    |> get_tag(tag_i)
    |> tpid
  end
  @spec tpid(binary, integer, integer) :: binary
  def tpid(packet, tag_i, value) do
    packet
    |> get_tag(tag_i)
    |> Packet.set_word(0, value)
  end

  @doc """
  Priority Code Point
  """
  @spec pcp(binary) :: 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7
  def pcp(tag) do
    tag
    |> Packet.get_byte(2)
    |> band(0xe0)
    |> bsr(5)
  end
  @spec pcp(binary, integer) :: 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7
  def pcp(packet, tag_i) do
    packet
    |> get_tag(tag_i)
    |> pcp
  end
  @spec pcp(binary, integer, integer) :: binary
  def pcp(packet, i, value) do
    packet
    |> Packet.set_byte(
      2, packet
      |> get_tag(i)
      |> Packet.get_byte(2)
      |> band(0x1f)
      |> bor(value |> band(0x07) |> bsl(5))
    )
  end

  @priorities [
    "Best Effort",
    "Background",
    "Excellent Effort",
    "Critical Applications",
    "Video, < 100 ms latency and jitter",
    "Voice, < 10 ms latency and jitter",
    "Internetwork Control",
    "Network Control"
  ]

  @spec pcp_to_string(binary) :: String.t
  def pcp_to_string(tag) do
    @priorities
    |> Enum.at(tag |> pcp)
  end
  @spec pcp_to_string(binary, integer) :: String.t
  def pcp_to_string(packet, tag_i) do
    @priorities
    |> Enum.at(packet |> pcp(tag_i))
  end

  @doc """
  Drop Eligible Indicator
  """
  @spec dei(binary) :: integer
  def dei(tag) do
    tag
    |> Packet.get_byte(2)
    |> band(0x10)
    |> bsr(4)
  end
  @spec dei(binary, integer) :: integer
  def dei(packet, tag_i) do
    packet
    |> get_tag(tag_i)
    |> dei
  end
  @spec dei(binary, integer, integer) :: binary
  def dei(packet, i, value) do
    orig = packet |> get_tag(i) |> Packet.get_byte(2)
    new = if value do
      orig ||| 0x10
    else
      orig &&& 0xef
    end
    packet
    |> Packet.set_byte(2, new)
  end

  @doc """
  VLAN Identifier
  """
  @spec vid(binary) :: integer
  def vid(tag) do
    tag
    |> Packet.get_word(2)
    |> band(0x0fff)
  end
  @spec vid(binary, integer) :: integer
  def vid(packet, tag_i) do
    packet
    |> get_tag(tag_i)
    |> vid
  end
  @spec vid(binary, integer, integer) :: binary
  def vid(packet, i, value) do
    orig = packet |> get_tag(i) |> Packet.get_word(2)
    new = (orig &&& 0xf000) ||| (value &&& 0x0fff)
    packet
    |> Packet.set_byte(2, new)
  end

end

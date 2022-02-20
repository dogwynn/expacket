defmodule ExPacket.Ethernet do
  alias ExPacket.Packet, as: Packet
  alias ExPacket.EthernetTag, as: EthernetTag
  use Bitwise

  @spec ether_type(binary) :: integer
  def ether_type(packet) do
    packet
    |> Packet.get_word(12 + 4 * EthernetTag.count(packet))
  end

  @spec header_size(binary) :: integer
  def header_size(packet) do
    14 + 4 * EthernetTag.count(packet)
  end

  @spec load(binary) :: binary
  def load(packet) do
    packet
    |> Packet.adjust(0, header_size(packet))
  end
end

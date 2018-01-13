defmodule CrimsonWeb.RoomChannel do
  use CrimsonWeb, :channel

  def join("rooms:" <> room_name, payload, socket) do
    if authorized?(payload) do
      send self(), {:init, room_name, payload["user_id"]}
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def terminate({:shutdown, :closed}, %{topic: "rooms:"<>room_name} = socket) do
    GenServer.call Rooms.Server, {:closed, room_name, self()}
    #IO.puts "closed"
  end
  def terminate({:shutdown, :left}, %{topic: "rooms:"<>room_name} = socket) do
    GenServer.call Rooms.Server, {:leave, room_name, self()}
    #IO.puts "left"
  end

  def handle_info({:init, room_name, user_id},socket) do
    case GenServer.call Rooms.Server, {:join, room_name, user_id, self()} do
      :joined -> IO.puts "joined"
      {:error, reason} -> IO.puts "error, reason: #{reason}"
    end

    {:noreply, socket}
  end

  defp authorized?(_payload) do
    true
  end
end

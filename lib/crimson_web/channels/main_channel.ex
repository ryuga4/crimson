defmodule CrimsonWeb.MainChannel do
  use CrimsonWeb, :channel

  def join("main", payload, socket) do
    if authorized?(payload) do
      send self(), {:init, payload}
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info({:init, payload}, socket) do
    rooms = GenServer.call Rooms.Server, :rooms
    push socket, "update_rooms", %{"rooms" => rooms}
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end

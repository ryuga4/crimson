defmodule Rooms.Room do
  @moduledoc false
  require Logger


  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: :"#{name}")
  end

  def init(name) do
    if true do
      Process.flag(:trap_exit, true)
    end
    :timer.apply_interval(100, GenServer, :call, [:"#{name}", :tick])
    {:ok, %{players: [], map: %Game.Map{width: 1000, height: 1000}, name: name}}
  end


  def handle_call(:tick, _from, state) do
    new_state = move state
    CrimsonWeb.Endpoint.broadcast! ("rooms:"<>state.name), "update", new_state
    {:noreply, new_state}
  end

  def handle_cast({:move, name, x, y}, %{players: players} = state) do
    moved =
      players
      |> Enum.map(fn i ->
        if i.name == name do
          Game.Player.move i, x, y
        else
          i
        end
      end)
    {:noreply, %{state | players: moved}}
  end

  def handle_cast({:join, name}, %{players: players} = state) do
    new_player = %Game.Player{name: name}
    {:noreply, %{state | players: [new_player | players]}}
  end

  def handle_cast(:check, state) do
    IO.puts "works!"
    {:noreply, state}
  end


  def move(state) do
    state
  end

  def terminate(reason,_state) do
    Logger.info "terminating: #{inspect self}: #{inspect reason}"
    :ok
  end
end
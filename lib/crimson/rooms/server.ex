defmodule Rooms.Server do
  @moduledoc false
  


  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    {:ok, %{rooms: []}}
  end



  def handle_call({:join, room_name, user_id, channel_pid}, _from, %{rooms: rooms} = state) do
    case add_member rooms, room_name, user_id, channel_pid do
      {:error, reason} -> {:reply, {:error, reason}, state}
      {:ok, new_rooms} ->
        GenServer.cast :"#{room_name}", {:join, user_id}
        {:reply, :joined,  %{state | rooms: new_rooms}}
    end
  end

  def handle_call({:leave, room_name, name}, _from, %{rooms: rooms} = state) when is_binary(name) do
    case Enum.split_with rooms, fn i -> i.room_name == room_name end do
      {[room], rest_rooms} ->
        new_members =
          case Enum.split_with room.members, fn i -> i.name == name end do
            {[member],rest_members} -> rest_members
            {[],rest_members} -> rest_members
          end
        new_rooms =
          [%{room | members: new_members} | rest_rooms]

        closed_empty_rooms = close_empty_rooms new_rooms
        CrimsonWeb.Endpoint.broadcast! "main", "update_rooms", %{"rooms" => rooms_format closed_empty_rooms}
        {:reply, :left, %{state | rooms: closed_empty_rooms}}
      {[],rooms} ->
        {:reply, :left_strange, %{state | rooms: rooms}}
    end
  end


  def handle_call({:leave, room_name, channel_pid}, _from,%{rooms: rooms} = state) when is_pid(channel_pid) do
    case Enum.split_with rooms, fn i -> i.room_name == room_name end do
      {[room], rest_rooms} ->
        new_members =
          case Enum.split_with room.members, fn i -> i.channel_pid == channel_pid end do
            {[member],rest_members} -> rest_members
            {[],rest_members} -> rest_members
          end
        new_rooms =
          [%{room | members: new_members} | rest_rooms]

        closed_empty_rooms = close_empty_rooms new_rooms
        CrimsonWeb.Endpoint.broadcast! "main", "update_rooms", %{"rooms" => rooms_format closed_empty_rooms}
        {:reply, :left, %{state | rooms: closed_empty_rooms}}
      {[],_} -> throw "left from not existing room"
    end
  end

  def handle_call({:closed, room_name, channel_pid}, _from, %{rooms: rooms} = state) do
    IO.puts "CLOSED"
    case Enum.split_with rooms, fn i -> i.room_name == room_name end do
      {[room], rest_rooms} ->
        {name,new_members} =
          case Enum.split_with room.members, fn i -> i.channel_pid == channel_pid end do
            {[member],rest_members} -> {member.name, [%{member | active: false} | rest_members]}
            {[],rest_members} -> {nil, rest_members}
          end
        new_rooms =
          [%{room | members: new_members} | rest_rooms]
        if name, do: Task.start_link fn -> disconnect_member! new_rooms, room_name, name end
        {:reply, :closed, %{state | rooms: new_rooms}}

      {[],_} ->
        IO.inspect rooms
        throw "closed connection to not existing room"
    end
  end

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:rooms, _from, state) do
    rooms = state.rooms |> rooms_format
    {:reply, rooms, state}
  end

  defp rooms_format(rooms) do
    rooms |>  Enum.map fn i -> %{name: i.room_name, members: Enum.count i.members} end
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end



  def active?(rooms, room_name, user_id) do
    room = rooms |>
      Enum.find(&(&1.room_name == room_name))
    if room do
      user =
        room.members
        |> Enum.find(&(&1.name == user_id))
      if user do
        user.active
      end
    end
  end

  defp disconnect_member!(rooms, room_name, user_id) do
    Process.sleep(10000)
    case active?(rooms, room_name, user_id) do
      false -> GenServer.call Rooms.Server, {:leave, room_name, user_id}
      _ -> nil
    end
  end

  defp close_empty_rooms(rooms) do
    case Enum.split_with rooms, fn i -> i.members == [] end do
      {[], rest_rooms} -> rest_rooms
      {empty_rooms, rest_rooms} ->
          for %{room_name: room_name} <- empty_rooms do
            Supervisor.delete_child(Rooms.Supervisor, :"#{room_name}")
            Supervisor.terminate_child(Rooms.Supervisor, :"#{room_name}")
          end
          rest_rooms
    end
  end

  defp add_member(rooms, room_name, user_id, channel_pid) do
    case Enum.split_with rooms, fn i -> i.room_name == room_name end do
      {[], rest_rooms} ->
        Supervisor.start_child(Rooms.Supervisor, Supervisor.child_spec({Rooms.Room, room_name}, id: :"#{room_name}"))
        new_room = %{room_name: room_name, members: [%{name: user_id, channel_pid: channel_pid, active: true}]}
        new_rooms = [new_room | rest_rooms]
        CrimsonWeb.Endpoint.broadcast! "main", "update_rooms", %{"rooms" => rooms_format new_rooms}
        {:ok, new_rooms}
      {[room], rest_rooms} ->
        case add_member room, user_id, channel_pid do
          {:ok, updated_room} ->
            new_rooms = [updated_room | rest_rooms]
            CrimsonWeb.Endpoint.broadcast! "main", "update_rooms", %{"rooms" => rooms_format new_rooms}
            {:ok, new_rooms}
          {:error, reason} -> {:error, reason}
        end
      _ ->
        IO.inspect rooms
        throw "more than one room with name: #{room_name}"
    end
  end
  def add_member(room, user_id, channel_pid) do
    case Enum.split_with room.members, fn i -> i.name == user_id end do
      {[], rest_users} ->
        new_user = %{name: user_id, channel_pid: channel_pid, active: true}
        {:ok, %{room | members: [new_user | rest_users]}}
      {[%{active: true}], _} ->
        {:error, "name \"#{user_id}\" is already taken"}
      {[%{active: false}], rest_users} ->
        new_user = %{name: user_id, channel_pid: channel_pid, active: true}
        {:ok, %{room | members: [new_user | rest_users]}}
      _ ->
        IO.inspect room
        throw "more than one user in room #{room}, with name #{user_id}"
    end
  end
end
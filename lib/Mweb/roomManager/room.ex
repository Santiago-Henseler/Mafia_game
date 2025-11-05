defmodule Mweb.RoomManager.Room do
  @moduledoc """
    Modulo encargado de manejar una room
  """
  require Timing
  require Constantes
  use GenServer

  alias Mweb.RoomManager.RoomStore
  alias Lmafia.Mafia

  def init(roomId) do
    {:ok, pid} = GenServer.start_link(Mafia, [])
    {:ok, %{roomId: roomId, players: [], gameController: pid, start: false}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def handle_cast({:removePlayer, pid},state) when is_pid(pid) do

    new_state = %{state | players: List.delete(state.players, pid)}

    case length(new_state.players) do
      0 -> RoomStore.removeRoom(new_state.roomId)
      _ -> :ok
    end

    {:noreply, new_state}
  end

  def handle_cast({:removePlayer, pid}, state) when is_pid(pid) do

    new_state = %{state | players: Enum.reject(state.players, fn player -> player.pid == pid end)}

    {:noreply, new_state}
  end

  def handle_cast({:removePlayer, userId}, state) do

    new_state = %{state | players: Enum.reject(state.players, fn player -> player.userName == userId end)}

    sendPlayers(new_state)

    case length(new_state.players) do
      0 -> RoomStore.removeRoom(new_state.roomId)
      _ -> :ok
    end

    {:noreply, new_state}
  end

  def handle_cast({:addPlayer, pc}, state) do
    state = %{state | players: state.players ++ [pc]}

    {:noreply, state}
  end

  def handle_cast({:addPlayer, pid, userId}, state) do

    id = %{userName: userId, pid: pid, alive: true}
    state = %{state | players: state.players ++ [id]}

   # sendPlayers(state)

    state =
      if length(state.players) == Constantes.nJUGADORES and not state.start do
        GenServer.cast(state.gameController, {:start, state.players})
        %{state | start: true}
      else
        state
      end

    {:noreply, state}
  end

  def handle_call({:gameAction, action}, _pid, state) do
    {:reply, GenServer.call(state.gameController, action),state}
  end

  def handle_call(:getPlayers, _pid, state) do
    {:reply, state.players, state}
  end

  def handle_call(:canJoin, _pid, state) do
    if state.start do
      {:reply, false, state}
    end

    {:reply, length(state.players) < Constantes.nJUGADORES, state}
  end

  def handle_call({:getName, userId}, _pid, state) do

    name =
    case existPlayer(userId, state) do
      true  -> userId <> "_" <> Integer.to_string(Enum.random(0.. 2**20))
      false -> userId
    end

    {:reply, name, state}
  end

  def handle_call(request, _pid, state) do
    {:reply, request, state}
  end

  defp sendPlayers(state) do
    # TODO: chequear si se esta usando
    {:ok, json} = Jason.encode(%{type: "users", users: Enum.map(state.players, fn p -> p.userName end)})
    for user <- state.players do
      send(user.pid, {:msg, json})
    end
  end

  defp existPlayer(username, state) do

    case Enum.find(state.players, fn p -> p.userName == username end) do
      nil -> false
      _   -> true
    end
  end
end

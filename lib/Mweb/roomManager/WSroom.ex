defmodule  Mweb.WSroom do
  @moduledoc """
    Modulo encargado de manejar las conexiones webSocket con el cliente
  """
  @behaviour :cowboy_websocket

  require Timing
  alias Mweb.RoomManager.RoomStore

  # Cuando un nuevo usuario se conecta a la room lo agrego
  def init(req = %{pid: ip, path_info: [roomId, userId]}, state) do
    GenServer.cast(RoomStore.getRoom(:RoomStore, roomId), {:addPlayer, ip, userId})
    {:cowboy_websocket, req, state, %{idle_timeout: :infinity}}
  end

  def websocket_init(status) do
    {:ok, status}
  end

  # Recibo un mensaje del usuario
  def websocket_handle({:text, msg}, state) do
    case Jason.decode(msg) do
      {:ok, %{"type" => "victimSelect", "roomId" => roomId, "victim" => victim}} -> # Momento que eligen la victima
        GenServer.call(RoomStore.getRoom(:RoomStore, roomId), {:gameAction, {:victimSelect, victim}})
        {:ok, state}
      {:ok, %{"type" => "saveSelect", "roomId" => roomId, "saved" => player}} -> # Momento que deciden el salvado
        GenServer.call(RoomStore.getRoom(:RoomStore, roomId), {:gameAction, {:saveSelect, player}})
        {:ok, state}
      {:ok, %{"type" => "guiltySelect", "roomId" => roomId, "guilty" => player}} -> # Se devuelve si es asesino o no
        isMafiaAnswer = GenServer.call(RoomStore.getRoom(:RoomStore, roomId), {:gameAction, {:isMafia, player}})
        timestamp = Timing.get_timestamp_stage(:transicion)
        {:reply, {:text, Jason.encode!(%{type: "action", action: "guiltyAnswer", answer: isMafiaAnswer, timestamp_guilty_answer: timestamp})}, state}
      {:ok, %{"type" => "finalVoteSelect", "roomId" => roomId, "voted" => voted}} ->
        GenServer.call(RoomStore.getRoom(:RoomStore, roomId), {:gameAction, {:finalVoteSelect, voted}})
        {:ok, state}
      _ ->
        {:ok, state}
    end
  end

  def websocket_handle(_other, status) do
    {:ok, status}
  end

  # Cuando el usuario cierra la conexion lo borro de la room
  def terminate(_reason, req, _status) do
    [_padd, _ws,_game, roomId, userId] = String.split(req.path, "/")

    GenServer.cast(RoomStore.getRoom(:RoomStore, roomId), {:removePlayer, userId})
    :ok
  end

  def websocket_info({:msg, payload}, state) do
    {:reply, {:text, payload}, state}
  end

  def websocket_info(info, state) do
    {:reply, {:text, "#{inspect(info)}"}, state}
  end
end

defmodule Mweb.Ruta do
  import Plug.Conn

  alias Mweb.RoomManager.RoomStore

  def init(state) do
    state
  end

  # Endpoint para chequear si se puede unir a una room
  def call(conn = %{method: "POST", path_info: [userId, roomId, "joinRoom"]}, _state) do
    roomPid = RoomStore.getRoom(:RoomStore, roomId)
    if roomPid != nil do
      if GenServer.call(roomPid, :canJoin) do
        name = GenServer.call(roomPid, {:getName, userId})
        {:ok, json} = Jason.encode(%{type: "canJoin", playerName: name, roomId: roomId})
        send_whit_cors(conn, 201, json)
      else
        send_whit_cors(conn, 404, "Room is full")
      end
    else
      send_whit_cors(conn, 404, "Room not found")
    end

  end

  # Endpoint para chequear si se puede unir a una Voiceroom
  def call(conn = %{method: "POST", path_info: [userId, roomId, "voiceRoom"]}, _state) do
    roomPid = RoomStore.getRoom(:RoomStore, roomId)
    if roomPid != nil do
      if GenServer.call(roomPid, :canJoin) do
        name = GenServer.call(roomPid, {:getName, userId})
        {:ok, json} = Jason.encode(%{type: "canJoin", playerName: name, roomId: roomId})
        send_whit_cors(conn, 201, json)
      else
        send_whit_cors(conn, 404, "Room is full")
      end
    else
      send_whit_cors(conn, 404, "Room not found")
    end

  end

  # Endpoint para crear nuevas rooms
  def call(conn = %{method: "POST", path_info: ["newRoom"]}, _state) do
    send_whit_cors(conn, 201,  Integer.to_string(RoomStore.createRoom(:RoomStore)))
  end

  # Endpoint para obtener todas las rooms actuales
  def call(conn = %{method: "GET", path_info: ["rooms"]},  _state) do
    {:ok, json} = :RoomStore |> RoomStore.getRooms |> Map.keys |> Jason.encode
    send_whit_cors(conn, 200, json)
  end

  def call(conn = %{method: "GET", path_info: [roomId]},  _state) when is_integer(roomId) do
    roomPid = RoomStore.getRoom(:RoomStore, roomId)

    jugadores = GenServer.call(roomPid, :getPlayers)
    {:ok, json} = Jason.encode(Enum.map(jugadores, fn p -> p.userName end))
    send_whit_cors(conn, 200, json)
  end

  def call(conn, _opts) do
    send_whit_cors(conn, 404, "Not found")
  end

  def send_whit_cors(conn, status, body) do
    # Agrego cabezeras al body para que el navegador no me bloquee las respuestas de este servidor
    conn
    |> put_resp_header("access-control-allow-origin", "*")
    |> put_resp_header("access-control-allow-methods", "GET, POST, PUT, DELETE, OPTIONS")
    |> put_resp_header("access-control-allow-headers", "content-type, authorization")
    |> send_resp(status, body)
  end

end

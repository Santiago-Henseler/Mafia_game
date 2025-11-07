defmodule Mweb.RoomManager.RoomStore do
  @moduledoc """
    Modulo encargado de manterne las distintas rooms almacendas por {roomId: roomPid}
  """
  use GenServer

  def start_link(name), do: GenServer.start_link(__MODULE__, :ok, name: name)

  # Casteos para llamar mas lindo al GenServer
  def createRoom(name), do: GenServer.call(name, {:createRoom})
  def createRoomFrom(name, roomId), do: GenServer.call(name, {:createRoomFrom, roomId})
  def removeRoom(name, roomId), do: GenServer.cast(name, {:removeRoom, roomId})
  def getRooms(name), do: GenServer.call(name, {:getRooms})
  def getRoom(name, roomId), do: GenServer.call(name, {:getRoom, roomId})

  def init(_params) do
    rooms = %{}
    {:ok, rooms}
  end

  def handle_info(_msg, rooms) do
    {:noreply, rooms}
  end

  def handle_cast({:removeRoom, roomId}, rooms) do
    roomPid = Map.get(rooms, roomId)
    Process.exit(roomPid, :normal)
    rooms = Map.delete(rooms, roomId)
    {:noreply, rooms}
  end

  def handle_call({:createRoom},_pid, rooms) do
    roomId = getRoomNumber(rooms)

    {:ok, roomPid} = GenServer.start(Mweb.RoomManager.Room, roomId)

    rooms = Map.put(rooms, roomId, roomPid)
    {:reply, roomId, rooms}
  end

  def handle_call({:createRoomFrom, roomId},_pid, rooms) do
    if Map.get(rooms, roomId) == nil do
      {:ok, roomPid} = GenServer.start(Mweb.RoomManager.Room, roomId)
      rooms = Map.put(rooms, roomId, roomPid)

      {:reply, roomId, rooms}
    else
      # no deberia poder llegar aca nunca
      raise "La habitación ya existia"
    end
  end

  def handle_call({:getRooms}, _pid, rooms) do
    {:reply, rooms, rooms}
  end

  def handle_call({:getRoom, roomId}, _pid, rooms) when is_integer(roomId) do
    {:reply, Map.get(rooms, roomId), rooms}
  end

  def handle_call({:getRoom, roomId}, _pid, rooms) do
    {:reply, Map.get(rooms, String.to_integer(roomId)), rooms}
  end

  def handle_call(request, _pid, rooms) do
    {:reply, request, rooms}
  end

  defp getRoomNumber(rooms) do
    roomId = Enum.random(0.. 2**20)
    key = Map.get(rooms, roomId)

    if key == nil do
      roomId
    else
      getRoomNumber(rooms)
    end
  end

end

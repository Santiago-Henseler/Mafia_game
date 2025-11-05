defmodule Mweb.RoomManager.RoomStore do
  @moduledoc """
    Modulo encargado de manterne las distintas rooms almacendas por {roomId: roomPid}
  """
  use GenServer

  def start_link([]), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  # Casteos para llamar mas lindo al GenServer
  def createRoom(), do: GenServer.call(__MODULE__, {:createRoom})
  def createRoomFrom(roomId), do: GenServer.call(__MODULE__, {:createRoomFrom, roomId})
  def removeRoom(roomId), do: GenServer.cast(__MODULE__, {:removeRoom, roomId})
  def getRooms(), do: GenServer.call(__MODULE__, {:getRooms})
  def getRoom(roomId), do: GenServer.call(__MODULE__, {:getRoom, roomId})

  def init(_params) do
    rooms = %{}
    {:ok, rooms}
  end

  def handle_info(_msg, rooms) do
    {:noreply, rooms}
  end

  def handle_cast({:removeRoom, roomId}, rooms) do
    # TODO: Deberia eliminar el proceso??
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
    # TODO: chequear que no exista esa room
    {:ok, roomPid} = GenServer.start(Mweb.RoomManager.Room, roomId)

    rooms = Map.put(rooms, roomId, roomPid)
    {:reply, roomId, rooms}
  end

  def handle_call({:getRooms}, _pid, rooms) do
    {:reply, rooms, rooms}
  end

  def handle_call({:getRoom, roomId}, _pid, rooms) when is_integer(roomId) do
    {:reply, Map.get(rooms, roomId), rooms}
  end

  def handle_call({:getRoom, roomId}, _pid, rooms)   do
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

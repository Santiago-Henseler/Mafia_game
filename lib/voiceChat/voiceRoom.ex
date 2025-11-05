defmodule VoiceChat.VoiceRoom do

  use GenServer
  alias Mweb.RoomManager.RoomStore

  def start_link([]), do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  # Casteos para llamar mas lindo al GenServer
  def createRoom(roomId), do: GenServer.call(__MODULE__, {:createRoom, roomId})
  def removeRoom(roomId), do: GenServer.cast(__MODULE__, {:removeRoom, roomId})
  def getPcsFromPid(pid), do: GenServer.call(__MODULE__, {:getPcsFromPid, pid})
  def joinRoom(roomId, pc), do: GenServer.cast(__MODULE__, {:joinRoom, roomId, pc})
  def leaveRoom(roomId, pid), do: GenServer.cast(__MODULE__, {:leaveRoom, roomId, pid})
  def handshakeDone(pc), do: GenServer.cast(__MODULE__, {:handshakeDone, pc})

  def init(_params) do
    # %{peerConectionPID: roomId}
    pcPid = %{}
    {:ok, pcPid}
  end

  def handle_info(_msg, pcPid) do
    {:noreply, pcPid}
  end

  def handle_call({:createRoom, roomId},_pid, pcPid) do
    # TODO: podriamos hacer como hacen las rooms del juego que no dan el id de room los users (?
    {:reply, RoomStore.createRoomFrom(roomId), pcPid}
  end

  def handle_call({:getPcsFromPid, pid}, _pid, pcPid) do
    roomId = Map.get(pcPid, pid)
    roomPid = RoomStore.getRoom(roomId)
    pcs = GenServer.call(roomPid, :getPlayers)

    {:reply, pcs, pcPid}
  end

  def handle_cast({:joinRoom, roomId, pc},  pcPid) do
    roomPid = RoomStore.getRoom(roomId)
    GenServer.cast(roomPid, {:addPlayer, pc})

    {:noreply, Map.put(pcPid, pc.pid, roomId)}
  end

  def handle_cast({:leaveRoom, roomId, pid},  pcPid) do
    roomPid = RoomStore.getRoom(roomId)
    GenServer.cast(roomPid, {:removePlayer, pid})

    {:noreply, Map.put(pcPid, pid, roomId)}
  end

  def handle_cast({:removeRoom, roomId}, pcPid) do
    RoomStore.removeRoom(roomId)
    {:noreply, pcPid}
  end

  def handle_cast({:handshakeDone, pc}, pcPid) do
    roomId = Map.get(pcPid, pc.pid)
    roomPid = RoomStore.getRoom(roomId)

    GenServer.cast(roomPid, {:removePlayer, pc.pid})
    GenServer.cast(roomPid, {:addPlayer, %{pid: pc.pid, out: pc.out, handshake: true}})

    {:noreply, pcPid}
  end

end

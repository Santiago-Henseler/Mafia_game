defmodule VoiceChat.PeerHandler do

  @behaviour :cowboy_websocket

  alias VoiceChat.VoiceRoom
  require Logger

  alias ExWebRTC.{
    ICECandidate,
    MediaStreamTrack,
    PeerConnection,
    RTPCodecParameters,
    SessionDescription
  }

  @ice_servers [
    %{urls: "stun:stun.l.google.com:19302"}
  ]

  @audio_codecs [
    %RTPCodecParameters{
      payload_type: 111,
      mime_type: "audio/opus",
      clock_rate: 48_000,
      channels: 2
    }
  ]

  def init(con = %{path_info: [roomId]}, _opts) do
    {:cowboy_websocket, con, String.to_integer(roomId), %{idle_timeout: :infinity}}
  end

  def websocket_init(roomId) do
    {:ok, pid} =
      PeerConnection.start_link(
        ice_servers: @ice_servers,
        audio_codecs: @audio_codecs
      )

    stream_id = MediaStreamTrack.generate_stream_id()
    audio_track = MediaStreamTrack.new(:audio, [stream_id])
    {:ok, _sender} = PeerConnection.add_track(pid, audio_track)

    peerConnection = %{pid: pid, out: audio_track.id, handshake: false}

    VoiceRoom.joinRoom(roomId, peerConnection)

    {:ok, %{
      peer_connection: peerConnection,
      out_audio_track_id: audio_track.id,
      in_audio_track_id: nil,
      pid: pid
    }}
  end

  def websocket_handle({:text, msg}, state) do
    case Jason.decode(msg) do
      {:ok, decoded} ->
        handle_ws_msg(decoded, state)

      {:error, reason} ->
        Logger.error("Failed to parse JSON message: #{inspect(reason)}")
        {:ok, state}
    end
  end

  def websocket_handle(other, status) do
    IO.inspect other
    {:ok, status}
  end

  # Handshacke del webRTC compartiendo iceCandidates
  defp handle_ws_msg(%{"type" => "offer", "data" => data}, state) do
    offer = SessionDescription.from_json(data)
    :ok = PeerConnection.set_remote_description(state.pid, offer)

    {:ok, answer} = PeerConnection.create_answer(state.pid)
    :ok = PeerConnection.set_local_description(state.pid, answer)

    answer_json = SessionDescription.to_json(answer)

    msg =
      %{"type" => "answer", "data" => answer_json}
      |> Jason.encode!()

    VoiceRoom.handshakeDone(state.peer_connection)
    {:reply, {:text, msg}, state}
  end

  defp handle_ws_msg(%{"type" => "ice", "data" => data}, state) do
    candidate = ICECandidate.from_json(data)
    :ok = PeerConnection.add_ice_candidate(state.pid, candidate)
    {:ok, state}
  end

  def terminate(reason, _state) do
    Logger.info("WebSocket connection was terminated, reason: #{inspect(reason)}")
  end

  def websocket_info({:EXIT, pid, reason}, %{pid: pid} = state) do
    Logger.info("Peer connection process exited, reason: #{inspect(reason)}")
    {:stop, {:shutdown, :pc_closed}, state}
  end

  # Mensajes de eventos de WebRTC
  def websocket_info({:ex_webrtc, _from, msg}, state) do
    handle_webrtc_msg(msg, state)
  end

  def websocket_info(info, state) do
    {:ok, {:text, "#{inspect(info)}"}, state}
  end

  # Manejo de los eventos webRTC
  defp handle_webrtc_msg({:ice_candidate, candidate}, state) do
    candidate_json = ICECandidate.to_json(candidate)

    msg =
      %{"type" => "ice", "data" => candidate_json}
      |> Jason.encode!()

    {:reply, {:text, msg}, state}
  end

  defp handle_webrtc_msg({:connection_state_change, conn_state}, state) do

    if conn_state == :failed do
      {:reply, {:shutdown, :pc_failed}, state}
    else
      {:ok, state}
    end
  end

  defp handle_webrtc_msg({:track, %MediaStreamTrack{id: id}}, state) do
    {:ok, %{state | in_audio_track_id: id}}
  end

  defp handle_webrtc_msg({:rtp, id, _src, packet}, %{in_audio_track_id: id} = state) do
    pcs = VoiceRoom.getPcsFromPid(state.pid)

    Enum.each(pcs, fn %{pid: pid, out: audioTrackOut, handshake: handshake} ->
      if pid != state.pid and handshake do
        :ok = PeerConnection.send_rtp(pid, audioTrackOut, packet)
      end
    end)

    {:ok, state}
  end

  defp handle_webrtc_msg(_msg, state), do: {:ok, state}
end

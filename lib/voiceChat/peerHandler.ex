defmodule VoiceChat.PeerHandler do

  @behaviour :cowboy_websocket

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

  @video_codecs [
    %RTPCodecParameters{
      payload_type: 96,
      mime_type: "video/VP8",
      clock_rate: 90_000
    }
  ]

  @audio_codecs [
    %RTPCodecParameters{
      payload_type: 111,
      mime_type: "audio/opus",
      clock_rate: 48_000,
      channels: 2
    }
  ]

  def init(con, _opts) do
    {:ok, pc} =
      PeerConnection.start_link(
        ice_servers: @ice_servers,
        video_codecs: @video_codecs,
        audio_codecs: @audio_codecs
      )

    stream_id = MediaStreamTrack.generate_stream_id()
    video_track = MediaStreamTrack.new(:video, [stream_id])
    audio_track = MediaStreamTrack.new(:audio, [stream_id])

    {:ok, _sender} = PeerConnection.add_track(pc, video_track)
    {:ok, _sender} = PeerConnection.add_track(pc, audio_track)

    state = %{
      peer_connection: pc,
      out_video_track_id: video_track.id,
      out_audio_track_id: audio_track.id,
      in_video_track_id: nil,
      in_audio_track_id: nil
    }

    {:cowboy_websocket, con, state}
  end

  def websocket_init(status) do
    {:ok, status}
  end

  def websocket_handle({:text, msg}, state) do
    dbg(msg)
    case Jason.decode(msg) do
      {:ok, decoded} ->
        handle_ws_msg(decoded, state)

      {:error, reason} ->
        Logger.error("Failed to parse JSON message: #{inspect(reason)}")
        {:ok, state}
    end
  end

  def websocket_handle(_other, status) do
    {:ok, status}
  end

  def terminate(reason, _state) do
    Logger.info("WebSocket connection was terminated, reason: #{inspect(reason)}")
  end

  # Mensajes desde el proceso del PeerConnection
  def websocket_info({:EXIT, pc, reason}, %{peer_connection: pc} = state) do
    Logger.info("Peer connection process exited, reason: #{inspect(reason)}")
    {:stop, {:shutdown, :pc_closed}, state}
  end

  def websocket_info({:relay_rtp, :audio, packet}, state) do
    PeerConnection.send_rtp(state.peer_connection, state.out_audio_track_id, packet)
    {:ok, state}
  end

  # Mensajes de eventos internos de ExWebRTC
  def websocket_info({:ex_webrtc, _from, msg}, state) do
    handle_webrtc_msg(msg, state)
  end

  def websocket_info({:msg, payload}, state) do
    {:reply, {:text, payload}, state}
  end

  def websocket_info(info, roomStore) do
    {:reply, {:text, "#{inspect(info)}"}, roomStore}
  end

  defp handle_ws_msg(%{"type" => "offer", "data" => data}, state) do
    offer = SessionDescription.from_json(data)
    :ok = PeerConnection.set_remote_description(state.peer_connection, offer)

    {:ok, answer} = PeerConnection.create_answer(state.peer_connection)
    :ok = PeerConnection.set_local_description(state.peer_connection, answer)

    answer_json = SessionDescription.to_json(answer)

    msg =
      %{"type" => "answer", "data" => answer_json}
      |> Jason.encode!()

    Logger.info("Sent SDP answer:\n#{answer_json["sdp"]}")

    {:reply, {:text, msg}, state}
  end

  defp handle_ws_msg(%{"type" => "ice", "data" => data}, state) do
    candidate = ICECandidate.from_json(data)
    :ok = PeerConnection.add_ice_candidate(state.peer_connection, candidate)
    {:ok, state}
  end

  defp handle_webrtc_msg({:connection_state_change, conn_state}, state) do
    if conn_state == :failed do
      {:reply, {:shutdown, :pc_failed}, state}
    else
      {:ok, state}
    end
  end

  defp handle_webrtc_msg({:ice_candidate, candidate}, state) do
    candidate_json = ICECandidate.to_json(candidate)

    msg =
      %{"type" => "ice", "data" => candidate_json}
      |> Jason.encode!()

    {:reply, {:text, msg}, state}
  end

  defp handle_webrtc_msg({:track, track}, state) do
    %MediaStreamTrack{kind: kind, id: id} = track

    state =
      case kind do
        :video -> %{state | in_video_track_id: id}
        :audio -> %{state | in_audio_track_id: id}
      end

    {:ok, state}
  end

  defp handle_webrtc_msg({:rtcp, packets}, state) do
    for packet <- packets do
      case packet do
        {_track_id, %ExRTCP.Packet.PayloadFeedback.PLI{}} when state.in_video_track_id != nil ->
          :ok = PeerConnection.send_pli(state.peer_connection, state.in_video_track_id, "h")

        _other ->
          # do something with other RTCP packets
          :ok
      end
    end

    {:ok, state}
  end

  defp handle_webrtc_msg({:rtp, id, nil, packet}, %{in_audio_track_id: id} = state) do

    # TODO: de alguna manera tengo que tener los pids de los usuarios que quiero que se puedan comunicar
    Enum.each(, fn pid ->
      send(pid, {:relay_rtp, :audio, packet})
    end)

    {:ok, state}
  end

  defp handle_webrtc_msg({:rtp, id, rid, packet}, %{in_video_track_id: id} = state) do
    # rid is the id of the simulcast layer (set in `priv/static/script.js`)
    # change it to "m" or "l" to change the layer
    # when simulcast is disabled, `rid == nil`
    if rid == "h" do
      PeerConnection.send_rtp(state.peer_connection, state.out_video_track_id, packet)
    end

    {:ok, state}
  end

  defp handle_webrtc_msg(_msg, state), do: {:ok, state}
end

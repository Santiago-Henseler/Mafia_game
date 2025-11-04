const peerConectionConfig = { 'iceServers': [{ 'urls': 'stun:stun.l.google.com:19302' },] };

const mediaConstraints = {video: {width: {ideal: 1280}, height: {ideal: 720}, frameRate: {ideal: 24}}, audio: true}
const videoPlayer = document.getElementById("videoPlayer");

const ws = new WebSocket("ws://localhost:4000/ws/voice");

ws.onopen = _ => start_connection(ws);
ws.onclose = event => console.log("WebSocket connection was terminated:", event);

async function start_connection(ws) {
    const peerConection = new RTCPeerConnection(peerConectionConfig);
    
    window.pc = peerConection;
    peerConection.ontrack = event => videoPlayer.srcObject = event.streams[0];
    peerConection.onicecandidate = event => iceEvent(event);

    const localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    peerConection.addTransceiver(localStream.getVideoTracks()[0], {
        direction: "sendrecv",
        streams: [localStream],
        sendEncodings: [
        { rid: "h", maxBitrate: 1200 * 1024},
        { rid: "m", scaleResolutionDownBy: 2, maxBitrate: 600 * 1024},
        { rid: "l", scaleResolutionDownBy: 4, maxBitrate: 300 * 1024 },
        ],
    });

    // replace the call above with this to disable simulcast
    // peerConection.addTrack(localStream.getVideoTracks()[0]);
    peerConection.addTrack(localStream.getAudioTracks()[0]);

    ws.onmessage = async event => messageEvent(event, peerConection);

    const offer = await peerConection.createOffer();
    await peerConection.setLocalDescription(offer);

    console.log("Sent SDP offer:", offer)
    ws.send(JSON.stringify({type: "offer", data: offer}));
};

function iceEvent(event){
    if (event.candidate === null) return;

    console.log("Sent ICE candidate:", event.candidate);
    ws.send(JSON.stringify({ type: "ice", data: event.candidate }));
}

async function messageEvent(event, peerConection){
    const {type, data} = JSON.parse(event.data);

    switch (type) {
      case "answer":
        console.log("Received SDP answer:", data);
        await peerConection.setRemoteDescription(data)
        break;
      case "ice":
        console.log("Received ICE candidate:", data);
        await peerConection.addIceCandidate(data);
    }
}
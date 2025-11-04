const peerConectionConfig = { 
    iceServers: [{ urls: 'stun:stun.l.google.com:19302' }]
};

const peerConection = new RTCPeerConnection(peerConectionConfig);

const audioPlayer = document.getElementById("audioPlayer");
const ws = new WebSocket("ws://localhost:4000/ws/voice");
  
ws.onopen = _ => start_connection(ws);
ws.onmessage = async event => messageEvent(event, peerConection);
ws.onclose = event => console.log("WebSocket connection was terminated:", event);

async function start_connection(ws) {
    window.pc = peerConection;

    peerConection.ontrack = (event) => {
        console.log("Received remote track", event.streams[0]);
        audioPlayer.srcObject = event.streams[0];
        audioPlayer.autoplay = true;
    };

    peerConection.onicecandidate = event => {
        if (event.candidate) {
            console.log("Sent ICE candidate:", event.candidate);
            ws.send(JSON.stringify({ type: "ice", data: event.candidate }));
        }
    };

    // Obtenemos el audio del navegador y lo agregamos a la conexión
    const localStream = await navigator.mediaDevices.getUserMedia({ audio: true });
    localStream.getAudioTracks().forEach((track) => peerConection.addTrack(track, localStream));

    // Creamos la offert donde se va a indicar el tipo de stream y codecs
    const offer = await peerConection.createOffer();
    await peerConection.setLocalDescription(offer);

    ws.send(JSON.stringify({ type: "offer", data: offer }));
}

async function messageEvent(event, peerConection) {
    const { type, data } = JSON.parse(event.data);
    switch (type) {
        case "answer":
            console.log("Received SDP answer");
            await peerConection.setRemoteDescription(new RTCSessionDescription(data));
            break;
        case "ice":
            console.log("Received ICE candidate");
            await peerConection.addIceCandidate(new RTCIceCandidate(data));
            break;
        default:
            console.log("Unknown message type:", type, data);
    }
}
  
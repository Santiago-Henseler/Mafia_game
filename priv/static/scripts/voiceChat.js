let webSocketVoiceChat = null;
const audioPlayer = document.getElementById("audioPlayer");

function startVoiceChat(){
    const peerConectionConfig = { 
        iceServers: [{ urls: 'stun:stun.l.google.com:19302' }]
    };
    
    const peerConection = new RTCPeerConnection(peerConectionConfig);
    webSocketVoiceChat = new WebSocket(`${WS_URL}/ws/voice/${roomId}`);
      
    webSocketVoiceChat.onopen = _ => startConnection(peerConection);
    webSocketVoiceChat.onmessage = async event => messageEvent(event, peerConection);
}

function finishVoiceChat(){
    if(webSocketVoiceChat == null)
        return;
    webSocketVoiceChat.close();
}

async function startConnection(peerConection) {
    window.pc = peerConection;

    // Recibimos el audio de los pares y lo reproducimos
    peerConection.ontrack = (event) => {
        audioPlayer.srcObject = event.streams[0];
        audioPlayer.autoplay = true;
    };

    peerConection.onicecandidate = event => {
        if (event.candidate) {
            webSocketVoiceChat.send(JSON.stringify({ type: "ice", data: event.candidate }));
        }
    };

    // Obtenemos el audio del navegador y lo agregamos a la conexión
    const localStream = await navigator.mediaDevices.getUserMedia({ audio: true });
    localStream.getAudioTracks().forEach((track) => peerConection.addTrack(track, localStream));

    // Creamos la offert donde se va a indicar el tipo de stream y codecs
    const offer = await peerConection.createOffer();
    await peerConection.setLocalDescription(offer);

    webSocketVoiceChat.send(JSON.stringify({ type: "offer", data: offer }));
}

async function messageEvent(event, peerConection) {
    const { type, data } = JSON.parse(event.data);
    switch (type) {
        case "answer":
            // SDP answer
            await peerConection.setRemoteDescription(new RTCSessionDescription(data));
            break;
        case "ice":
            // ICE candidate
            await peerConection.addIceCandidate(new RTCIceCandidate(data));
            break;
        default:
            console.log("[ERROR] Unknown message type:", type, data);
    }
}
  
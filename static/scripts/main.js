const IP = "52.14.112.59";
const PUERTO = 4000;
const WEB_URL = `https://${IP}:${PUERTO}`;
const WS_URL = `wss://${IP}:${PUERTO}`;

let roomId = null;
let socket = null;
let playerName = null;

function initSession(){
    const labelName = document.getElementById("jugador");
    playerName = labelName.value;

    document.getElementById("session").style.display = "none";
    getRooms();
}

function connectWebSocket(){

    if(roomId == null || playerName == null || playerName == "")
        return;

    document.body.innerHTML += '<div id="players"></div>'

    socket = new WebSocket(`${WS_URL}/ws/game/${roomId}/${playerName}`)

    socket.onmessage = (event) => {
        data = JSON.parse(event.data)
        switch (data.type){
            case "users": 
                setPlayers(data.users);
                break;
            case "characterSet": 
                setCharacter(data.character);
                startGame(data.timestamp_game_starts);
                break;
            case "action":
                doAction(data);
                break;
            case "debug":
                console.log(`[DEBUG]: ${data}`);
                break;
            default: console.log(`[ERROR] Unknown message type: ${data}`)
        }
    }
}

const IP = "3.139.220.52";
const PUERTO = 4000;
const WEB_URL = `http://${IP}:${PUERTO}`;
const WS_URL = `ws://${IP}:${PUERTO}`;

let roomId = null;
let socket = null;
let playerName = null;

function initSession(){
    const labelName = document.getElementById("jugador");
    
    playerName = labelName.value;

    if (playerName == null || playerName == "") {
        alert('Por favor, ingrese un nombre.');
        return;
        }

    document.getElementById("session").classList.add('d-none');
    getRooms();
}

function showScreen(id) {
    const screens = ["session", "roomsSection", "currentRoomSection", "gameSection"];
    screens.forEach(s => {
        document.getElementById(s).classList.add("d-none");
    });
    document.getElementById(id).classList.remove("d-none");

    document.body.classList.add("gameplay-active");
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
                if ( data.character != "Muerto" && data.character != "Linchado" ) {
                    startGame(data.timestamp_game_starts);
                }
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

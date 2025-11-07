const IP = "192.168.0.120"; 
const PUERTO = 4000;
const WEB_URL = `http://${IP}:${PUERTO}`;
const WS_URL = `ws://${IP}:${PUERTO}`;

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

    socket.onopen = () => {
        getCharacters();
        setInterval(() => {
            if (socket.readyState === WebSocket.OPEN) {
                socket.send(JSON.stringify({type: "ping"}));
            }
        }, 25000);
    }

    socket.onmessage = (event) => {
        console.log(event.data)
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
                console.log(data);
                break;
            case "pong": break;
        }
    }
}

function getRooms(){

    if(roomId != null)
        return

    const roomSelection = document.getElementById("roomsTable")
    document.getElementById('roomsSection').classList.remove('d-none');

    let rooms = 0;

    fetch(`${WEB_URL}/rooms`, {method: "GET"})
    .then(response => response.json())
    .then(data => {
        if(data.length == 0){
            setTimeout(() => {
                getRooms();
              }, 3000);  
        }
        data.forEach(id => {
            const row = document.createElement('tr');
        
            row.innerHTML = `
                <td class="fw-semibold text-center">${id}</td>
                <td class="text-center">
                    <button class="btn btn-primary btn-sm border-0" onclick="joinRoom(${id})">Unirse</button>
                </td>
            `;
        
            roomSelection.appendChild(row); 
        });
    });
}

function createRoom(){
    document.getElementById('roomsSection').classList.add('d-none');

    fetch(`${WEB_URL}/newRoom/`, {method: "POST"})
    .then(response => response.text())
    .then(data => {
        roomId = data;  
        showRoomUI(roomId);
        connectWebSocket();
    });
}

function joinRoom(id){
    document.getElementById('roomsSection').classList.add('d-none');

    roomId = id

    fetch(`${WEB_URL}/${playerName}/${roomId}/joinRoom/`, {method: "POST"})
    .then(response => response.json())
    .then(data => {
        playerName = data.playerName
        showRoomUI(roomId);
        connectWebSocket();
    });
}

function getCharacters(){

    const options = {
        method: "GET",
      };
      
    fetch(`${WEB_URL}/${roomId}`, options)
        .then(response => response.json())
        .then(data => {
            setPlayers(data)
        });
}

function setPlayers(users){
    document.getElementById("gamePlayers").textContent = "Usuarios conectados: " + users;
}

function showRoomUI(roomId) {
    showScreen("gameSection");

    document.getElementById("gameRoomId").textContent = roomId;
    document.getElementById("gamePlayers").textContent = "Usuarios conectados: 0";
    document.getElementById("gameTitle").textContent = "Esperando más jugadores...";
    document.getElementById("gameContent").innerHTML = "";
    document.getElementById("gameActions").innerHTML = "";
}

function clearGameUI() {
    document.getElementById("gameTitle").textContent = "";
    document.getElementById("gameContent").innerHTML = "";
    document.getElementById("gameActions").innerHTML = "";
}
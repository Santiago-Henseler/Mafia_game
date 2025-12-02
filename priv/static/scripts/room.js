function getRooms(){

      const roomSelection = document.getElementById("roomsTable")
      document.getElementById('roomsSection').classList.remove('d-none');

    fetch(`${WEB_URL}/rooms`, {method: "GET"})
    .then(response => response.json())
    .then(data => {
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

    fetch(`${WEB_URL}/newRoom/`, {method: "POST"})
    .then(response => response.text())
    .then(data => {
        roomId = data;  
//        header.innerHTML += `<center><h1>Room Id: ${roomId}</h1></center>`
//        document.getElementById("roomSelection").style.display = "none"
        showRoomUI(roomId);
        connectWebSocket();
    });
}

function joinRoom(id){
    roomId = id

    fetch(`${WEB_URL}/${playerName}/${roomId}/joinRoom/`, {method: "POST"})
    .then(response => response.json())
    .then(data => {
        playerName = data.playerName
//        header.innerHTML += `<center><h1>Room Id: ${data.roomId}</h1></center>`
//        document.getElementById("roomSelection").style.display = "none"
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
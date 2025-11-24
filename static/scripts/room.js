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

    const container = document.getElementById("players");
    container.innerHTML = `<center>
                                <div>
                                    <h4>Usuarios conectados: ${users}</h4>
                                </div>    
                            </center>`

}

function showRoomUI(roomId) {
    // Ocultar login y lista de salas
    document.getElementById("session").classList.add("d-none");
    document.getElementById("roomsSection").classList.add("d-none");

    // Mostrar pantalla de sala
    document.getElementById("currentRoomSection").classList.remove("d-none");
    document.getElementById("currentRoomId").innerText = roomId;
}
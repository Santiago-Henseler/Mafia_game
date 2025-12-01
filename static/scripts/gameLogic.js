let character = null;

function getImage(characterType){
    switch(characterType){
        case "Mafioso": return 'img/mafia.jpg';
        case "Medico": return 'img/medico.jpg';
        case "Policia": return 'img/policia.jpg';
        case "Aldeano": return 'img/campesino.jpg';
        case "Muerto": return 'img/muerto.jpeg';
        case "Linchado": return 'img/linchado.jpg';
        default: console.log("Tipo de personaje "+characterType+" no encontrado");
    }
}

function setCharacter(characterType) {
    document.body.style.backgroundImage = `url('${getImage(characterType)}')`;
    document.body.style.backgroundSize = "cover";
    document.body.style.backgroundRepeat = "no-repeat";
    document.body.style.backgroundPosition = "center center";
}

function startGame(timestampGameStarts) {


    showScreen("gameSection");

    document.getElementById("gameTitle").textContent =
        "La partida está por comenzar";
    
    document.getElementById("gameContent").innerHTML =
        `<h3 id="startTimer"></h3>`;

    document.getElementById("gameActions").innerHTML = "";

    timer(getTimeForNextStage(timestampGameStarts), (time)=>{
        const timerLabel = document.getElementById("startTimer");

        if (!timerLabel) return;

        timerLabel.textContent = "La partida inicia en " + time;

        if(time === 1){
            timerLabel.remove();        
            document.getElementById("gameTitle").textContent = "";
        }
    });
}

function doAction(action){

    switch(action.action){
        case "selectVictim":
            selectVictim(action.victims, action.timestamp_select_victims)
            break;
        case "savePlayer":
            savePlayer(action.players, action.timestamp_select_saved)
            break;
        case "selectGuilty":
            selectGuilty(action.players, action.timestamp_select_guilty)
            break;
        case "guiltyAnswer":
            guiltyAnswer(action.answer, action.timestamp_guilty_answer)
            break;
        case "nightResult":
            nightResult(action.result, action.timestamp_night_result)
            break;
        case "discusion":
            discusion(action.players, action.timestamp_final_discusion)
            break;
        case "discusionResult":
            discussionResult(action.mensaje, action.timestamp)
            break;
        case "goodEnding":
            alert(action.mensaje)
            break;
        case "badEnding":
            alert(action.mensaje)
            break;
        default: break;
    }
}

function discusion(players, timestampVote) {
    startVoiceChat();
    showScreen("gameSection");

    document.getElementById("gameTitle").textContent = "Selecciona quien crees que es un mafioso";
    document.getElementById("gameContent").innerHTML = `
        <h3 id="finalVoteTimer"></h3>
    `;

    const actions = document.getElementById("gameActions");

    let optionsContainer = document.createElement("div");
    optionsContainer.id = "finalVoteOptions";
    actions.appendChild(optionsContainer);

    let voted = null;
    setRadiosHelper("finalVoteOptions",players,"finalvote", (value) => { 
        voted=value;
    });

    timer(getTimeForNextStage(timestampVote), (time)=>{
        document.getElementById("finalVoteTimer").innerText =
            "La seleccion de mafioso PARA ECHARLO termina en " + time;

        if(time == 1){
            finishVoiceChat();
            socket.send(JSON.stringify({roomId: roomId, type: "finalVoteSelect", voted: voted}));
            clearGameUI();
        }
    });
}

function discussionResult(mensaje, timestamp) {
    showScreen("gameSection");

    document.getElementById("gameTitle").textContent = mensaje;
    document.getElementById("gameContent").innerHTML = `
        <h3 id="discussionResultTimer"></h3>
    `;

    timer(getTimeForNextStage(timestamp), (time)=>{
        document.getElementById("discussionResultTimer").innerText =
            "Proxima etapa en " + time;

        if(time == 1){
            clearGameUI();
        }
    });
}

function nightResult(result, timestamp) {
    showScreen("gameSection");

    document.getElementById("gameTitle").textContent = result;
    document.getElementById("gameContent").innerHTML = `
        <h3 id="nightResultTimer"></h3>
    `;

    timer(getTimeForNextStage(timestamp), (time)=>{
        document.getElementById("nightResultTimer").innerText =
            "Votación final en " + time;

        if(time == 1){
            clearGameUI();
        }
    });
}

function guiltyAnswer(answer, timestamp) {
    showScreen("gameSection");

    document.getElementById("gameTitle").textContent = answer;
    document.getElementById("gameContent").innerHTML = `
        <h3 id="guiltyAnswerTimer"></h3>
    `;

    timer(getTimeForNextStage(timestamp), (time)=>{
        document.getElementById("guiltyAnswerTimer").innerText =
            "La confirmación de sospechas termina en " + time;

        if(time == 1){
            clearGameUI();
        }
    });
}

function selectGuilty(players, timestampGuilty){
    showScreen("gameSection");

    document.getElementById("gameTitle").textContent = "Selecciona quien sospechas que es el asesino";
    document.getElementById("gameContent").innerHTML = `
        <h3 id="guiltyTimer"></h3>
    `;
    const actions = document.getElementById("gameActions");

    let optionsContainer = document.createElement("div");
    optionsContainer.id = "guiltyOptions";
    actions.appendChild(optionsContainer);

    let guilty = null;
    setRadiosHelper("guiltyOptions",players,"guilty", (value) => { 
        guilty=value;
    });

    timer(getTimeForNextStage(timestampGuilty), (time)=>{
        document.getElementById("guiltyTimer").innerText =
            "La seleccion de sospecha termina en " + time;

        if(time == 1){
            socket.send(JSON.stringify({roomId: roomId, type: "guiltySelect", guilty: guilty}));
            clearGameUI();
        }
    });
}

function savePlayer(players, timestampSave){
    showScreen("gameSection");

    document.getElementById("gameTitle").textContent = "Selecciona a quien curar";
    document.getElementById("gameContent").innerHTML = `
        <h3 id="saveTimer"></h3>
    `;

    const actions = document.getElementById("gameActions");

    let optionsContainer = document.createElement("div");
    optionsContainer.id = "saveOptions";
    actions.appendChild(optionsContainer);

    let saved = null;
    setRadiosHelper("saveOptions",players,"saved", (value) => { 
        saved=value;
    });

    timer(getTimeForNextStage(timestampSave), (time)=>{
        document.getElementById("saveTimer").innerText =
            "La seleccion de salvado termina en " + time;

        if(time == 1){
            socket.send(JSON.stringify({roomId: roomId, type: "saveSelect", saved: saved}));
            clearGameUI();
        }
    });
}

function selectVictim(victims, timestampSelectVictim){
    startVoiceChat();
    showScreen("gameSection");

    document.getElementById("gameTitle").textContent = "Selecciona tu víctima";

    document.getElementById("gameContent").innerHTML = `
        <h3 id="victimTimer"></h3>
    `;

    const actions = document.getElementById("gameActions");

    let optionsContainer = document.createElement("div");
    optionsContainer.id = "victimOptions";
    actions.appendChild(optionsContainer);

    let victim = null;
    setRadiosHelper("victimOptions",victims,"victim", (value) => { 
        victim=value;
    });

    timer(getTimeForNextStage(timestampSelectVictim), (time)=>{
        document.getElementById("victimTimer").innerText =
            "La selección de víctima termina en " + time;

        if(time == 1){
            finishVoiceChat();
            socket.send(JSON.stringify({ type: "victimSelect",roomId: roomId,victim: victim }));
            clearGameUI();
        }
    });
}

function timer(time, fn){
    let cuentaRegresiva = setInterval(() => {
        fn(time)
        time--;
        if(time == 0){
            clearInterval(cuentaRegresiva);
        }
    }, 1000);

}

function getTimeForNextStage(timestampNextStage) {
    let CurrentDate = new Date()
    let NextStageDate = new Date(timestampNextStage)
    let result = Math.floor( ( NextStageDate.getTime() - CurrentDate.getTime() ) / 1000  )

    if (result > 0) 
        return result
    else {
        console.warn("Este cliente se quedo detras por " + result + " segundos")
        return 1 
    }
}


function setRadiosHelper(containerId, list, groupName, onChangeCallback) {
    const container = document.getElementById(containerId);
    container.innerHTML = ""; 
    
    list.forEach(name => {
        const id = `opt-${groupName}-${name}`;

        container.insertAdjacentHTML(
            "beforeend",
            `
            <label class="select-option fade-in" id="${id}">
                <input type="radio" name="${groupName}" value="${name}">
                <strong>${name}</strong>
            </label>
            `
        );
    });

    // Attach events
    const radios = document.querySelectorAll(`input[name="${groupName}"]`);
    radios.forEach(radio => {
        radio.addEventListener("change", () => {
            // visual effect
            document
                .querySelectorAll(`label.select-option`)
                .forEach(l => l.classList.remove("selected"));

            radio.parentElement.classList.add("selected");

            // callback with selected value
            onChangeCallback(radio.value);
        });
    });
}
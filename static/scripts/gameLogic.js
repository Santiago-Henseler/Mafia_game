let character = null;

function getImage(characterType){
    switch(characterType){
        case "Mafioso": return 'img/mafia.jpg';
        case "Medico": return 'img/medico.jpg';
        case "Policia": return 'img/policia.jpg';
        case "Aldeano": return 'img/campesino.jpg';
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
        case "discusion":
            discusion(action.players, action.timestamp_final_discusion)
            break;
        case "discusionResult":
            alert(action.mensaje)
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
    let voted = null;

    let finalVoteSeccion = document.getElementById("finalVoteSeccion")
    if (!finalVoteSeccion){
        document.body.insertAdjacentHTML("beforeend",`
            <div id="finalVoteSeccion">
                    <center>
                        <h2>Selecciona quien crees que es un mafioso</h2>
                        <h3 id="finalVoteTimer"></h3>
                    </center>
                <div id="finalVoteOptions"></div>
            </div>`); 
        finalVoteSeccion = document.getElementById("finalVoteSeccion")
    }
    finalVoteSeccion.style.display = "block";
    const optionsContainer = document.getElementById("finalVoteOptions");
    optionsContainer.innerHTML = "";

    timer(getTimeForNextStage(timestampVote), (time)=>{
        let timer = document.getElementById("finalVoteTimer")
        timer.innerText = "La seleccion de mafioso PARA ECHARLO termina en " +time;

        if(time == 1){
            finishVoiceChat();
            finalVoteSeccion.style.display = "none";
            socket.send(JSON.stringify({roomId: roomId, type: "finalVoteSelect", voted: voted}));
        }
    })

    for(let p of players){
        optionsContainer.insertAdjacentHTML("beforeend", `
        <label>
            <input type="radio" name="voted" value="${p}"> ${p}
        </label>
        <label id="${p}Count"></label>
        <br>
    `);

    }

    const radios = document.querySelectorAll('input[name="voted"]');

    radios.forEach(radio => {
      radio.addEventListener("change", () => {
        voted = radio.value
      });
    })    
}

function guiltyAnswer(answer, timestamp) {
    document.body.insertAdjacentHTML("beforeend",`
        <div id="guiltyAnsweSeccion">
                <center>
                    <h2>${answer}</h2>
                    <h3 id="guiltyAnswerTimer"></h3>
                </center>
        </div>`); 
    let guiltyAnsweSeccion = document.getElementById("guiltyAnsweSeccion")

    timer(getTimeForNextStage(timestamp), (time)=>{
        let timer = document.getElementById("guiltyAnswerTimer");
        timer.innerText = "La confirmación de sospechas termina en " +time;

        if(time == 1){
            guiltyAnsweSeccion.remove();
        }
    })
}

function selectGuilty(players, timestampGuilty){
    showScreen("gameSection");

    document.getElementById("gameTitle").textContent = "Selecciona quien sospechas que es el asesino";
    document.getElementById("gameContent").innerHTML = `
        <h3 id="guiltyTimer"></h3>
    `;
    const actions = document.getElementById("gameActions");
    actions.innerHTML = "";             // limpiar contenido previo

    let optionsContainer = document.createElement("div");
    optionsContainer.id = "guiltyOptions";
    actions.appendChild(optionsContainer);

    for(let v of players){
        optionsContainer.insertAdjacentHTML("beforeend", `
            <label>
                <input type="radio" name="guilty" value="${v}"> ${v}
            </label>
            <label id="${v}Count"></label>
            <br>
        `);
    }

    const radios = document.querySelectorAll('input[name="guilty"]');
    radios.forEach(radio => {
        radio.addEventListener("change", () => {
            guilty = radio.value;
        });
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
    actions.innerHTML = "";             // limpiar contenido previo

    let optionsContainer = document.createElement("div");
    optionsContainer.id = "saveOptions";
    actions.appendChild(optionsContainer);

    for(let v of players){
        optionsContainer.insertAdjacentHTML("beforeend", `
            <label>
                <input type="radio" name="saved" value="${v}"> ${v}
            </label>
            <label id="${v}Count"></label>
            <br>
        `);
    }

    let saved = null;
    const radios = document.querySelectorAll('input[name="saved"]');
    radios.forEach(radio => {
        radio.addEventListener("change", () => {
            saved = radio.value;
        });
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
    let victim = null;

    document.getElementById("gameTitle").textContent = "Selecciona tu víctima";

    document.getElementById("gameContent").innerHTML = `
        <h3 id="victimTimer"></h3>
    `;

    const actions = document.getElementById("gameActions");
    actions.innerHTML = ""; // limpiar contenido previo

    let optionsContainer = document.createElement("div");
    optionsContainer.id = "victimOptions";
    actions.appendChild(optionsContainer);

    for(let v of victims){
        optionsContainer.insertAdjacentHTML("beforeend", `
            <label>
                <input type="radio" name="victim" value="${v}"> ${v}
            </label>
            <label id="${v}Count"></label>
            <br>
        `);
    }

    const radios = document.querySelectorAll('input[name="victim"]');
    radios.forEach(radio => {
        radio.addEventListener("change", () => {
            victim = radio.value;
        });
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

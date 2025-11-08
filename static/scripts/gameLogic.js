let character = null;

function setCharacter(characterType){
    character = characterType

    document.body.innerHTML += `<center><h3>Sos un ${character}</h3></center>`;
}

function startGame(timestampGameStarts){
    document.body.innerHTML += '<center><h3 id="startTimer"></h3></center>'
    
    timer( getTimeForNextStage(timestampGameStarts), (time)=>{
        let timer = document.getElementById("startTimer")
        timer.innerText = "La partida inicia en " +time;

        if(time == 1){
            timer.style.display = "none"
        }
    })
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
    let guilty = null;

    let guiltySeccion = document.getElementById("guiltySeccion")
    if (!guiltySeccion){
        document.body.insertAdjacentHTML("beforeend",`
            <div id="guiltySeccion">
                    <center>
                        <h2>Selecciona quien sospechas que es el asesino</h2>
                        <h3 id="guiltyTimer"></h3>
                    </center>
                <div id="guiltyOptions"></div>
            </div>`); 
        guiltySeccion = document.getElementById("guiltySeccion")
    }
    guiltySeccion.style.display = "block";
    const optionsContainer = document.getElementById("guiltyOptions");
    optionsContainer.innerHTML = "";

    timer(getTimeForNextStage(timestampGuilty), (time)=>{
        let timer = document.getElementById("guiltyTimer")
        timer.innerText = "La seleccion de sospecha termina en " +time;

        if(time == 1){
            guiltySeccion.style.display = "none";
            socket.send(JSON.stringify({roomId: roomId, type: "guiltySelect", guilty: guilty}));
        }
    })

    for(let g of players){
        optionsContainer.insertAdjacentHTML("beforeend", `
        <label>
            <input type="radio" name="guilty" value="${g}"> ${g}
        </label>
        <label id="${g}Count"></label>
        <br>
    `);

    }

    const radios = document.querySelectorAll('input[name="guilty"]');

    radios.forEach(radio => {
      radio.addEventListener("change", () => {
        guilty = radio.value
      });
    })    
}

function savePlayer(players, timestampSave){
    let saved = null;

    let saveSeccion = document.getElementById("saveSeccion")
    if (!saveSeccion){
        document.body.insertAdjacentHTML("beforeend",`
            <div id="saveSeccion">
                    <center>
                        <h2>Selecciona a quien curar</h2>
                        <h3 id="saveTimer"></h3>
                    </center>
                <div id="saveOptions"></div>
            </div>`); 
        saveSeccion = document.getElementById("saveSeccion")
    }
    saveSeccion.style.display = "block";
    const optionsContainer = document.getElementById("saveOptions");
    optionsContainer.innerHTML = "";

    timer(getTimeForNextStage(timestampSave), (time)=>{
        let timer = document.getElementById("saveTimer")
        timer.innerText = "La seleccion de salvado termina en " + time;

        if(time == 1){
            saveSeccion.style.display = "none";
            socket.send(JSON.stringify({roomId: roomId, type: "saveSelect", saved: saved}));
        }
    })

    for(let save of players){
        optionsContainer.insertAdjacentHTML("beforeend", `
        <label>
            <input type="radio" name="saved" value="${save}"> ${save}
        </label>
        <label id="${save}Count"></label>
        <br>
    `);

    }

    const radios = document.querySelectorAll('input[name="saved"]');

    radios.forEach(radio => {
      radio.addEventListener("change", () => {
        saved = radio.value
      });
    })
}

function selectVictim(victims, timestampSelectVictim){
    startVoiceChat();
    let victim = null;

    let victimSeccion = document.getElementById("victimSeccion")
    if (!victimSeccion){
        document.body.insertAdjacentHTML("beforeend",`
            <div id="victimSeccion">
                    <center>
                        <h2>Selecciona tu victima</h2>
                        <h3 id="victimTimer"></h3>
                    </center>
                <div id="victimOptions"></div>
            </div>`); 
        victimSeccion = document.getElementById("victimSeccion")
    } 

    victimSeccion.style.display = "block" ; 
    const optionsContainer = document.getElementById("victimOptions");
    optionsContainer.innerHTML = "";

    timer(getTimeForNextStage(timestampSelectVictim), (time)=>{
        let timer = document.getElementById("victimTimer")
        timer.innerText = "La seleccion de victima termina en " +time;
        
        if(time == 1){
             finishVoiceChat();
            victimSeccion.style.display = "none";
            socket.send(JSON.stringify({type: "victimSelect",roomId: roomId, victim: victim}));
        }
    })

    for(let victim of victims){
        optionsContainer.insertAdjacentHTML("beforeend", `
        <label>
            <input type="radio" name="victim" value="${victim}"> ${victim}
        </label>
        <label id="${victim}Count"></label>
        <br>
    `);
    }

    const radios = document.querySelectorAll('input[name="victim"]');
    radios.forEach(radio => {
      radio.addEventListener("change", () => {
        victim = radio.value
      });
    })
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

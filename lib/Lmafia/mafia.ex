defmodule Lmafia.Mafia do
  require Constantes
  require Timing
  alias Lmafia.Votacion

  use GenServer

  def init(_param) do

    {:ok, pid} = GenServer.start_link(Votacion, [])

    {:ok,  %{
      aldeanos:  [], # 4 aldeanos
      medicos:   [], # 2 medicos
      mafiosos:  [], # 2 mafiosos
      policias:  [], # 2 policias

      votacion:     pid,
      victimSelect: nil,
      saveSelect:   [],
      sobredosis:   [],
      muertos:      [],
    }}
  end

  def handle_cast({:start, players}, gameInfo) do
    # Seteamos roles e informamos jugadores
    gameInfo = gameInfo
      |> setCharacters(players)
      |> sendCharacterToPlayer()

    Process.send_after(self(), :selectVictim, Timing.get_time(:start)) # A los 20 segundos inicia la partida
    {:noreply, gameInfo}
  end

  def handle_call({:finalVoteSelect, voted}, _pid, gameInfo) do
    GenServer.cast(gameInfo.votacion, {:addVote, voted})
    {:reply, nil,  gameInfo}
  end

  def handle_call({:victimSelect, victimId}, _pid, gameInfo) do
    dbg(victimId)
    GenServer.cast(gameInfo.votacion, {:addVote, victimId})
    {:reply, nil, gameInfo}
  end

  def handle_call({:saveSelect, saveId},_pid, gameInfo) do
    GenServer.cast(gameInfo.votacion, {:addVote, saveId})
    {:reply,nil, gameInfo}
  end

  def handle_call({:isMafia, suspectId},_pid,gameInfo) when suspectId != nil do
    {:reply, isMafia(gameInfo.mafiosos, suspectId), gameInfo}
  end

  def handle_call({:isMafia, nil},_pid,state) do
    {:reply, "No ingreso sospecha, perdió el turno", state}
  end

  def handle_info(:selectVictim, gameInfo) do
    timestamp = Timing.get_timestamp_stage(:selectVictim)
    victims = get_jugadores(:vivos,gameInfo)
    {:ok, json} = Jason.encode(%{type: "action", action: "selectVictim", victims: Enum.map(victims, fn p -> p.userName end), timestamp_select_victims: timestamp})
    multicast(gameInfo.mafiosos, json)
    Process.send_after(self(), :kill, Timing.get_time(:selectVictim))
    {:noreply, gameInfo}
  end

  def handle_info(:kill, gameInfo) do
    victimSelect = getWin(gameInfo, :mafiosos)
    Process.send_after(self(), :medics, Timing.get_time(:transicion))
    {:noreply, %{gameInfo | victimSelect: victimSelect}}
  end

  def handle_info(:medics, gameInfo) do
    timestamp = Timing.get_timestamp_stage(:medics)
    players = get_jugadores(:vivos, gameInfo)
    {:ok, json} = Jason.encode(%{type: "action", action: "savePlayer", players: Enum.map(players, fn p -> p.userName end), timestamp_select_saved: timestamp})
    multicast(gameInfo.medicos, json)

    Process.send_after(self(), :cure, Timing.get_time(:medics))
    {:noreply, gameInfo}
  end

  def handle_info(:cure, gameInfo) do
    {sobredosis, curados} = getWin(gameInfo, :medics)
    gameInfo = %{gameInfo | saveSelect: curados, sobredosis: sobredosis}

    Process.send_after(self(), :policias, Timing.get_time(:transicion))
    {:noreply, gameInfo}
  end

  def handle_info(:policias, gameInfo) do
    timestamp = Timing.get_timestamp_stage(:policias)
    players = get_jugadores(:vivos, gameInfo)
    {:ok, json} = Jason.encode(%{type: "action", action: "selectGuilty", players: Enum.map(players, fn p -> p.userName end), timestamp_select_guilty: timestamp})
    multicast(gameInfo.policias, json)

    Process.send_after(self(), :preDiscussion, Timing.get_time(:policias))
    {:noreply, gameInfo}
  end

  def handle_info(:preDiscussion, gameInfo) do
    {result,gameInfo} = night_result(gameInfo)
    IO.puts result
    timestamp = Timing.get_timestamp_stage(:preDiscussion)
    players = get_jugadores(:all, gameInfo)
    {:ok, json} = Jason.encode(%{type: "action", action: "nightResult", result: result, timestamp_select_guilty: timestamp})
    multicast(players, json)

    Process.send_after(self(), :discussion, Timing.get_time(:preDiscussion))
    {:noreply, gameInfo}
  end

  def handle_info(:discussion, gameInfo) do
    timestamp = Timing.get_timestamp_stage(:discussion)
    users = get_jugadores(:vivos,gameInfo)
    {:ok, json} = Jason.encode(%{type: "action", action: "discusion", players: Enum.map(users, fn p -> p.userName end), timestamp_final_discusion: timestamp})
    multicast(users,json)

    Process.send_after(self(), :defineDiscussion, Timing.get_time(:discussion))
    {:noreply, gameInfo}
  end

  def handle_info(:defineDiscussion, gameInfo) do
    # Si hubo quorum para echar a alguien, se lo echa
    echado = getWin(gameInfo, :discussion)
    gameInfo = user_pasa_a_muertos(gameInfo,echado)
    mensaje =
      if echado do
        "Decision final: " <> echado <> " fue linchado"
      else
        "Decision final: Nadie fue linchado"
      end

    timestamp = Timing.get_timestamp_stage(:transicion)
    users = get_jugadores(:all, gameInfo)
    {:ok, json} = Jason.encode(%{type: "action", action: "discusionResult", mensaje: mensaje, timestamp_define_discusion: timestamp})
    multicast(users,json)

    Process.send_after(self(), {:endDiscussion, echado}, Timing.get_time(:transicion))
    {:noreply, gameInfo}
  end

  def handle_info({:endDiscussion, echado}, gameInfo) do
    # Si hubo quorum para echar a alguien, se lo echa
    gameInfo = user_pasa_a_muertos(gameInfo, echado)

    # Definicion final
    # Si cant mafiosos >= cant resto  -> Ganaron los mafiosos
    # Si cant mafiosos = 0            -> Gano el pueblo
    # Sino, sigue el juego
    cant_mafiosos = get_len_vivos(:mafiosos, gameInfo)
    cant_pueblo = get_len_vivos(:pueblo, gameInfo)

    timestamp = Timing.get_time(:transicion)
    cond do
      cant_mafiosos == 0 ->
        Process.send_after(self(), :goodEnding, timestamp)
      cant_mafiosos >= cant_pueblo ->
        Process.send_after(self(), :badEnding, timestamp)
      true ->
        Process.send_after(self(), :selectVictim, timestamp)
      end

    {:noreply, gameInfo}
  end

  def handle_info(:goodEnding, gameInfo) do
    users = get_jugadores(:all, gameInfo)
    mensaje = "Gano el pueblo!!!!"
    {:ok, json} = Jason.encode(%{type: "action", action: "goodEnding", mensaje: mensaje})
    multicast(users,json)

    {:noreply, gameInfo}
  end

  def handle_info(:badEnding, gameInfo) do
    users = get_jugadores(:all, gameInfo)
    mensaje = "Ganaron los mafiosos :( "
    {:ok, json} = Jason.encode(%{type: "action", action: "badEnding", mensaje: mensaje})
    multicast(users,json)

    {:noreply, gameInfo}
  end

  defp get_jugadores(:all,gameInfo) do
    players = gameInfo.mafiosos ++ gameInfo.medicos ++ gameInfo.aldeanos ++ gameInfo.policias ++ gameInfo.muertos
    players = Enum.shuffle(players)
    Enum.map(players, fn x -> if x.alive do x end end)
  end

  defp get_jugadores(:vivos,gameInfo) do
    players = gameInfo.mafiosos ++ gameInfo.medicos ++ gameInfo.aldeanos ++ gameInfo.policias
    players = Enum.shuffle(players)
    Enum.map(players, fn x -> if x.alive do x end end)
  end

  defp get_len_vivos(:mafiosos, gameInfo), do: Enum.count(gameInfo.mafiosos, fn x -> x.alive end)
  defp get_len_vivos(:policias, gameInfo), do: Enum.count(gameInfo.policias, fn x -> x.alive end)
  defp get_len_vivos(:aldeanos, gameInfo), do: Enum.count(gameInfo.aldeanos, fn x -> x.alive end)
  defp get_len_vivos(:medicos, gameInfo), do: Enum.count(gameInfo.medicos, fn x -> x.alive end)
  defp get_len_vivos(:pueblo, gameInfo) do
    get_len_vivos(:aldeanos, gameInfo) + get_len_vivos(:policias, gameInfo) + get_len_vivos(:medicos, gameInfo)
  end

  defp user_pasa_a_muertos(gameInfo, nil), do: gameInfo

  defp user_pasa_a_muertos(gameInfo, userName) do
    {mafiosos_muertos,mafiosos} = user_en_grupo_pasa_a_muertos(gameInfo.mafiosos, userName)
    {aldeanos_muertos,aldeanos} = user_en_grupo_pasa_a_muertos(gameInfo.aldeanos, userName)
    {policias_muertos,policias} = user_en_grupo_pasa_a_muertos(gameInfo.policias, userName)
    {medicos_muertos,medicos}   = user_en_grupo_pasa_a_muertos(gameInfo.medicos , userName)

    muertos = medicos_muertos ++ mafiosos_muertos ++ aldeanos_muertos ++ policias_muertos
    %{gameInfo | aldeanos: aldeanos, mafiosos: mafiosos ,medicos:  medicos, policias:  policias, muertos: muertos}
  end

  defp user_en_grupo_pasa_a_muertos(lista_grupo, userName) do
    Enum.split_with(lista_grupo, fn player -> player.userName == userName end)
  end

  defp setCharacters(gameInfo, players) do
#    players = Enum.shuffle(players)

    {aldeanos, rest}  = Enum.split(players, Constantes.nALDEANOS)
    {medicos,  rest}  = Enum.split(rest, Constantes.nMEDICOS)
    {mafiosos, rest}  = Enum.split(rest, Constantes.nMAFIOSOS)
    {policias, _rest} = Enum.split(rest, Constantes.nPOLICIAS)

    %{gameInfo | aldeanos: aldeanos, mafiosos: mafiosos ,medicos:  medicos, policias:  policias}
  end

  defp sendCharacterToPlayer(characters) do
    timestamp = Timing.get_timestamp_stage(:start)

    {:ok, json} = Jason.encode(%{type: "characterSet", character: "Aldeano", timestamp_game_starts: timestamp})
    multicast(characters.aldeanos, json)
    {:ok, json} = Jason.encode(%{type: "characterSet", character: "Medico", timestamp_game_starts: timestamp})
    multicast(characters.medicos, json)
    {:ok, json} = Jason.encode(%{type: "characterSet", character: "Mafioso", timestamp_game_starts: timestamp})
    multicast(characters.mafiosos, json)
    {:ok, json} = Jason.encode(%{type: "characterSet", character: "Policia", timestamp_game_starts: timestamp})
    multicast(characters.policias, json)

    characters
  end

  defp multicast(clientes, mensaje_json) do
    Enum.each(clientes, fn x ->
      if x.alive == true do
        send(x.pid, {:msg, mensaje_json})
      end
    end)
  end

  defp getWin(gameInfo, stage) do
    winner = GenServer.call(gameInfo.votacion, {:getWin, stage})
    GenServer.cast(gameInfo.votacion, :restart)
    dbg(winner)
    winner
  end

  defp night_result(gameInfo) do
    result =
      if gameInfo.victimSelect do
        if gameInfo.victimSelect in gameInfo.saveSelect do
          "La mafia quiso asesinar a " <> gameInfo.victimSelect <> " pero fue salvado por los médicos"
        else
          gameInfo = user_pasa_a_muertos(gameInfo, gameInfo.victimSelect)
          base = "La mafia asesinó a " <> gameInfo.victimSelect

          if gameInfo.victimSelect in gameInfo.sobredosis do
            base <> " y mientras agonizaba recibió una sobredosis de cura"
          else
            base
          end
        end
      else
        "La mafia no asesinó a nadie"
      end

    sobredosis =
      for name <- gameInfo.sobredosis,
          name != gameInfo.victimSelect do
        name
      end

    result = if sobredosis != nil do
      result <> "\nMuertos por sobredosis:\n" <> Enum.join(sobredosis, "\n")
    else
      result
    end

    gameInfo = Enum.reduce(sobredosis, gameInfo, fn name, gi ->
      user_pasa_a_muertos(gi, name)
    end)

    {result, reset_selectors(gameInfo)}
  end

  defp reset_selectors(gameInfo) do
    %{gameInfo | victimSelect: nil, saveSelect: [], sobredosis: []}
  end

  defp isMafia(mafiosos, username ) do
    isMafia = Enum.any?(mafiosos, fn m -> m.userName == username end)
    format_isMafia_answer(isMafia,username)
  end

  defp format_isMafia_answer(isMafia,username) when is_integer(username) do
    format_isMafia_answer(isMafia,to_string(username))
  end

  defp format_isMafia_answer(isMafia,player) do
    "#{player}#{if isMafia, do: "", else: " no"} es un mafioso"
  end

end

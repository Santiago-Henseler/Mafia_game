defmodule Lmafia.Votacion do

  use GenServer

  def init(_param) do
    {:ok,  %{}}
  end

  def handle_cast(:restart, _voteInfo) do
    {:noreply, %{}}
  end

  def handle_cast({:addVote, vote}, voteInfo) do
    len = Map.get(voteInfo, vote)

    voteInfo =
      if len == nil do
        Map.put(voteInfo, vote, 1)
      else
        Map.put(voteInfo, vote, len+1)
      end

    {:noreply, voteInfo}
  end

  def handle_cast({:removeVote, vote}, voteInfo) do
    voteInfo |> dbg
    vote |> dbg

    len = Map.get(voteInfo, vote)

    voteInfo =
      if len != nil do
        %{voteInfo | vote: len-1}
      end

    {:noreply, voteInfo}
  end

  def handle_call({:getWin, stage},_pid, voteInfo) do
    {:reply, getMax(stage, voteInfo), voteInfo}
  end

  defp returnResultadoVotacion(:mafiosos, votos) do
    top2 = votos |> Enum.take(2)
    {firstK, firstV} = Enum.at(top2, 0)
    {_secondK, secondV} = Enum.at(top2, 1)

    if firstV == secondV do
      nil
    else
      firstK
    end
  end

  defp returnResultadoVotacion(:medics, votos) do
    {sobredosis, salvados} =
      votos
        |> Enum.reduce({[], []}, fn {player, votes}, {acc_sobredosis,acc_salvados} ->
          cond do
            votes > 1 -> {[player | acc_sobredosis], acc_salvados}
            votes == 1 -> {acc_sobredosis, [player | acc_salvados]}
            true -> {acc_sobredosis, acc_salvados}
        end
      end)

    {sobredosis, salvados}
  end

  defp returnResultadoVotacion(:discussion, votos) do
    # La decision final se comporta igual que los mafiosos. No hay quorum, no hace nada
    returnResultadoVotacion(:mafiosos,votos)
  end

  defp returnResultadoVotacion(_, votos) do
    # Por las dudas, default es por quorum
    returnResultadoVotacion(:mafiosos,votos)
  end

  defp getMax(stage, voteInfo) when map_size(voteInfo) >= 2 do
    votos_ordenados = voteInfo |> Enum.sort_by(fn {_k, v} -> v end, :desc)
    returnResultadoVotacion(stage,votos_ordenados)
  end

  defp getMax(stage, voteInfo) when map_size(voteInfo) > 0 do
    if stage == :medics do
      dbg(voteInfo)
      {firstK, _firstV} = Enum.at(voteInfo, 0)
      {[], [firstK]}
    else
      {firstK, _firstV} = Enum.at(voteInfo, 0)
      firstK
    end
  end

  defp getMax(_atom, _voteInfo), do: nil

end

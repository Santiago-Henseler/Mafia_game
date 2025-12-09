defmodule Constantes do
    @moduledoc false
    @aldeanos 1
    @mafiosos 1
    @policias 1
    @medicos 1

    @tiempo_transicion_estado 3000  #  3 segundos
    @tiempo_inicio_partida 10000    # 10 segundos
    @tiempo_debate_grupo 35000      #  35 segundos
    @tiempo_debate_final 40000     #  40 segundos

    @port 4000
    @publicport 8080

    defmacro nALDEANOS, do: @aldeanos
    defmacro nMAFIOSOS, do: @mafiosos
    defmacro nPOLICIAS, do: @policias
    defmacro nMEDICOS, do: @medicos
    defmacro nJUGADORES, do: @aldeanos + @mafiosos + @policias + @medicos

    defmacro tINICIO_PARTIDA, do: @tiempo_inicio_partida
    defmacro tTRANSICION, do: @tiempo_transicion_estado
    defmacro tDEBATE_GRUPO, do: @tiempo_debate_grupo
    defmacro tDEBATE_FINAL, do: @tiempo_debate_final
    defmacro tRESPUESTA, do: 2 * @tiempo_transicion_estado

    defmacro ePORT, do: @port
    defmacro pPORT, do: @publicport
end

defmodule Timing do
    require Constantes

    def get_time(:start), do: Constantes.tINICIO_PARTIDA
    def get_time(:transicion), do: Constantes.tTRANSICION
    def get_time(:selectVictim), do: Constantes.tDEBATE_GRUPO
    def get_time(:medics), do: Constantes.tDEBATE_GRUPO
    def get_time(:policias), do: Constantes.tDEBATE_GRUPO + Constantes.tRESPUESTA
    def get_time(:preDiscussion), do: Constantes.tRESPUESTA
    def get_time(:discussion), do: Constantes.tDEBATE_FINAL

    def get_timestamp_stage(:start) do
        timestamp_plus_miliseconds(Constantes.tINICIO_PARTIDA)
    end

    def get_timestamp_stage(:selectVictim) do
        timestamp_plus_miliseconds(Constantes.tDEBATE_GRUPO)
    end

    def get_timestamp_stage(:medics) do
        timestamp_plus_miliseconds(Constantes.tDEBATE_GRUPO)
    end

    def get_timestamp_stage(:policias) do
        timestamp_plus_miliseconds(Constantes.tDEBATE_GRUPO)
    end

    def get_timestamp_stage(:preDiscussion) do
        timestamp_plus_miliseconds(Constantes.tRESPUESTA)
    end

    def get_timestamp_stage(:discussion) do
        timestamp_plus_miliseconds(Constantes.tDEBATE_FINAL)
    end

    def get_timestamp_stage(:transicion) do
        timestamp_plus_miliseconds(Constantes.tTRANSICION)
    end

    def get_timestamp_stage(:policiasGuiltyAnswer) do
        timestamp_plus_miliseconds(Constantes.tRESPUESTA)
    end

    def timestamp_plus_miliseconds(miliseconds) do
        DateTime.add(DateTime.utc_now(),miliseconds, :millisecond)
    end
end

defmodule Constantes do
    @moduledoc false
    @aldeanos 1
    @mafiosos 1
    @policias 1
    @medicos 1

    @tiempo_transicion_estado 1000  #  1 segundo
    @tiempo_inicio_partida 5000    # 10 segundos
    @tiempo_debate_grupo 10000      #  1 minuto
    @tiempo_debate_final 10000     #  3 minutos

    defmacro nALDEANOS, do: @aldeanos
    defmacro nMAFIOSOS, do: @mafiosos
    defmacro nPOLICIAS, do: @policias
    defmacro nMEDICOS, do: @medicos
    defmacro nJUGADORES, do: @aldeanos + @mafiosos + @policias + @medicos

    defmacro tINICIO_PARTIDA, do: @tiempo_inicio_partida
    defmacro tTRANSICION, do: @tiempo_transicion_estado
    defmacro tDEBATE_GRUPO, do: @tiempo_debate_grupo
    defmacro tDEBATE_FINAL, do: @tiempo_debate_final
end

defmodule Timing do
    require Constantes

    def get_time(:start), do: Constantes.tINICIO_PARTIDA
    def get_time(:transicion), do: Constantes.tTRANSICION
    def get_time(:selectVictim), do: Constantes.tDEBATE_GRUPO
    def get_time(:medics), do: Constantes.tDEBATE_GRUPO
    def get_time(:policias), do: Constantes.tDEBATE_GRUPO
    def get_time(:preDiscussion), do: Constantes.tDEBATE_GRUPO
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
        timestamp_plus_miliseconds(Constantes.tDEBATE_GRUPO)
    end

    def get_timestamp_stage(:discussion) do
        timestamp_plus_miliseconds(Constantes.tDEBATE_FINAL)
    end

    def get_timestamp_stage(:transicion) do
        timestamp_plus_miliseconds(Constantes.tTRANSICION)
    end

    def timestamp_plus_miliseconds(miliseconds) do
        DateTime.add(DateTime.utc_now(),miliseconds, :millisecond)
    end
end

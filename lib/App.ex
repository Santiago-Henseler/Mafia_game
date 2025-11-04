defmodule App do
  @moduledoc false
  require Constantes
  use Application
  alias Mweb.RoomManager.RoomStore

  @impl true
  def start(_type, _args) do

    GenServer.start_link(RoomStore, "", name: RoomStore)

    dispatch = [
      {:_,
       [
         {"/ws/game/[...]", Mweb.WSroom, []},
         {"/ws/voice", VoiceChat.PeerHandler, []},
         {:_, Plug.Cowboy.Handler, {Mweb.Ruta, []}}
       ]}
    ]

    children = [
      {Plug.Cowboy,
       scheme: :http,
       plug: Mweb.Ruta,
       options: [port: Constantes.ePORT, dispatch: dispatch]},
    ]

    opts = [strategy: :one_for_one, name: Mweb.Supervisor]
    Supervisor.start_link(children, opts)
  end

end

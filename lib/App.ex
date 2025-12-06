defmodule App do
  @moduledoc false
  require Constantes
  use Application

  alias Mweb.RoomManager.RoomStore
  alias VoiceChat.VoiceRoom

  @impl true
  def start(_type, _args) do

    GenServer.start_link(RoomStore, "", name: :RoomStore)
    GenServer.start_link(VoiceRoom, "", name: VoiceRoom)

    dispatch = [
      {:_,
       [
         {"/ws/game/[...]", Mweb.WSroom, []},
         {"/ws/voice/[...]", VoiceChat.PeerHandler, []},
         {:_, Plug.Cowboy.Handler, {Mweb.Ruta, []}}
       ]}
    ]

    children = [
      {
        Plug.Cowboy,
        scheme: :https,
        plug: Mweb.Ruta,
        options: [
		      cipher_suite: :strong,
      		keyfile: "/etc/letsencrypt/live/myapp.3.139.220.52.sslip.io/privkey.pem",
		      certfile: "/etc/letsencrypt/live/myapp.3.139.220.52.sslip.io/fullchain.pem",
		      port: Constantes.ePORT, 
		      dispatch: dispatch
      	]
      },
      {
        Plug.Cowboy,
        scheme: :https,
        plug: Mweb.RutaPublica,
        options: [
		      cipher_suite: :strong,
		      keyfile: "/etc/letsencrypt/live/myapp.3.139.220.52.sslip.io/privkey.pem",
		      certfile: "/etc/letsencrypt/live/myapp.3.139.220.52.sslip.io/fullchain.pem",
		      port: Constantes.pPORT
      	]
      }    
    ]

    opts = [strategy: :one_for_one, name: Mweb.Supervisor]
    Supervisor.start_link(children, opts)
  end

end

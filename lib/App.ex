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
                keyfile: "/home/ec2-user/Mafia_game/priv/certs/privkey.pem",
                      certfile: "/home/ec2-user/Mafia_game/priv/certs/fullchain.pem",
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
                      keyfile: "/home/ec2-user/Mafia_game/priv/certs/privkey.pem",
                      certfile: "/home/ec2-user/Mafia_game/priv/certs/fullchain.pem",
                      port: Constantes.pPORT
        ]
      }    
    ]

    opts = [strategy: :one_for_one, name: Mweb.Supervisor]
    Supervisor.start_link(children, opts)
  end

end

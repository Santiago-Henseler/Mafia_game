defmodule Mweb.RutaPublica do
  use Plug.Router
  plug Plug.Logger 
  plug Plug.Static, at: "/static", from: :m_web

  plug :match        
  plug :dispatch     

  get "/" do
    file = :code.priv_dir(:m_web)
      |> Path.join("static/assets/index.html")
    
      send_file(conn, 200, file)
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end
end

# Mafia 

## Instrucciones de ejecucción 

$ mix deps.get

$ mix run --no-halt 

Para configurar IP editar la variable IP en main.js 

En el navegador abrir dos pestañas con el archivo  

file://${path_tp}/static/assets/index.html

En la consola del navegador ejecutar startVoiceChat()

Escuchar el eco 

## Elixir Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `voice_chat` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:voice_chat, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/voice_chat>.


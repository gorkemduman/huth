use Mix.Config

try do
  config :huth,
    json: "config/application_default_credentials_huth.json" |> Path.expand |> File.read!
rescue
  _ -> :ok
end

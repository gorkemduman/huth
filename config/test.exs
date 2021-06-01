use Mix.Config

config :huth,
  json: "test/data/home/huawei/application_default_credentials_huth.json" |> Path.expand |> File.read!

# config :bypass, enable_debug_log: true

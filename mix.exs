defmodule Huth.Mixfile do
  use Mix.Project

  def project do
    [
      app: :huth,
      version: "0.0.1",
      description: description(),
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: [warnings_as_errors: false],
      elixir: "~> 1.4",
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Huth, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:joken, "~> 2.0"},
      {:jason, "~> 1.1"},
      {:httpoison, "~> 1.0"},
      {:bypass, "~> 0.1", only: :test},
      {:plug_cowboy, "~> 1.0", only: :test},
      {:mix_test_watch, "~> 0.2", only: :dev},
      {:ex_doc, "~> 0.19", only: :dev},
      {:credo, "~> 0.8", only: [:test, :dev]},
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false}
    ]
  end

  defp description do
    """
    A simple library to generate and retrieve Oauth2 tokens for use with Huawei Cloud Service accounts.
    """
  end

  defp package do
    [
      maintainers: ["Phil Burrows"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/peburrows/huth"}
    ]
  end
end

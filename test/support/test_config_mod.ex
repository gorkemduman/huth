defmodule Huth.TestConfigMod do
  use Huth.Config

  def init(config) do
    {:ok, Keyword.put(config, :actor_email, :val)}
  end
end

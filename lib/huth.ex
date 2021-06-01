defmodule Huth do
  use Application

  @moduledoc """
  Huawei + Auth = Huth.
  """

  # for now, just spin up the supervisor
  def start(_type, _args) do
    Huth.Supervisor.start_link
  end
end

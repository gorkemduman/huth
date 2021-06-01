defmodule Huth.ConfigTest do
  use ExUnit.Case
  alias Huth.Config

  def check_config(map) do
    check_config(map, fn key -> Config.get(key) end)
  end

  def check_config(map, get_config) do
    map
    |> Map.keys()
    |> Enum.each(fn key ->
      assert {:ok, map[key]} == get_config.(key)
    end)
  end

  setup do
    bypass = Bypass.open()
    bypass_url = "http://localhost:#{bypass.port}"
    Application.put_env(:huth, :metadata_url, bypass_url)
    {:ok, bypass: bypass}
  end

  test "setting and retrieving value" do
    Config.set(:key, "123")
    assert {:ok, "123"} == Config.get(:key)
  end

  test "setting a value by atom can be retrieved by string" do
    Config.set(:random, "value")
    assert {:ok, "value"} == Config.get("random")
  end

  test "setting a value by string can be retrieved by atom" do
    Config.set("totally", "cool")
    assert {:ok, "cool"} == Config.get(:totally)
  end

  test "the initial state is what's passed in from the app config" do
    "test/data/test-credentials.json"
    |> Path.expand()
    |> File.read!()
    |> Jason.decode!()
    |> check_config(fn key -> Config.get(key) end)
  end

  test "dynamically add configs without interfering with existing accounts" do
    original_config = "test/data/test-credentials.json"
    |> Path.expand()
    |> File.read!()
    |> Jason.decode!()

    dynamic_config = "test/data/test-credentials-2.json"
    |> Path.expand()
    |> File.read!()
    |> Jason.decode!()

    Config.add_config(dynamic_config)

    check_config(original_config)
    check_config(dynamic_config, fn key -> Config.get(dynamic_config["client_email"], key) end)
  end

  test "the initial state has the token_source set to oauth_jwt" do
    assert {:ok, :oauth_client_credential} == Config.get(:token_source)
  end

  test "Config can start up with no config when disabled" do
    saved_config = Application.get_all_env(:huth)
    try do
      [:json, :metadata_url]
      |> Enum.each(&Application.delete_env(:huth, &1))
      Application.put_env(:huth, :disabled, true, persistent: true)

      {:ok, pid} = GenServer.start_link(Huth.Config, :ok)
      assert Process.alive?(pid)
    after
      Application.delete_env(:huth, :disabled)
      Enum.each(saved_config, fn {k, v} ->
        Application.put_env(:huth, k, v, persistent: true)
      end)
    end
  end

  test "hms default credential scope is found", %{bypass: bypass} do# The test configuration sets an example JSON blob. We override it briefly
    # during this test.
    current_json = Application.get_env(:huth, :json)
    new_json = "test/data/home/huawei/application_default_credentials_huth.json" |> Path.expand() |> File.read!()

    Application.put_env(:huth, :json, new_json, persistent: true)
    Application.stop(:huth)

    # default config requires below
    # Fake project response
#    project = "test-project"
#
#    Bypass.expect(bypass, fn conn ->
#      uri = "/computeMetadata/v1/project/project-id"
#      assert(conn.request_path == uri, "Huth should ask for project ID")
#      Plug.Conn.resp(conn, 200, project)
#    end)

    Application.start(:huth)

    state =
      "test/data/home/huawei/application_default_credentials_huth.json"
      |> Path.expand()
      |> File.read!()
      |> Jason.decode!()
      |> Config.map_config()

    Enum.each(state, fn {account, config} ->
      Enum.each(config, fn {key, _} ->
        assert {:ok, config[key]} == Config.get(account, key)
      end)

      assert {:ok, :oauth_client_credential} == Config.get(account, :token_source)
    end)

    # Restore original config
    Application.put_env(:huth, :json, current_json, persistent: true)
    Application.stop(:huth)
    Application.start(:huth)
  end

  test "multiple credentials are parsed correctly" do
    # The test configuration sets an example JSON blob. We override it briefly
    # during this test.
    current_json = Application.get_env(:huth, :json)
    new_json = "test/data/test-multicredentials.json" |> Path.expand() |> File.read!()

    Application.put_env(:huth, :json, new_json, persistent: true)
    Application.stop(:huth)

    Application.start(:huth)

    state =
      "test/data/test-multicredentials.json"
      |> Path.expand()
      |> File.read!()
      |> Jason.decode!()
      |> Config.map_config()

    Enum.each(state, fn {account, config} ->
      Enum.each(config, fn {key, _} ->
        assert {:ok, config[key]} == Config.get(account, key)
      end)

      assert {:ok, :oauth_client_credential} == Config.get(account, :token_source)
    end)

    # Restore original config
    Application.put_env(:huth, :json, current_json, persistent: true)
    Application.stop(:huth)
    Application.start(:huth)
  end

  test "huawei default credentials are found", %{bypass: bypass} do
    # The test configuration sets an example JSON blob. We override it briefly
    # during this test.
    current_json = Application.get_env(:huth, :json)
    Application.put_env(:huth, :json, "test/data/home/huawei/application_default_credentials_huth.json" |> Path.expand |> File.read!, persistent: true)
    Application.stop(:huth)


    Application.start(:huth)

    state =
      "test/data/home/huawei/application_default_credentials_huth.json"
      |> Path.expand()
      |> File.read!()
      |> Jason.decode!()

    check_config(state)
    assert {:ok, :oauth_client_credential} == Config.get(:token_source)

    # Restore original config
    Application.put_env(:huth, :json, current_json, persistent: true)
    Application.stop(:huth)
    Application.start(:huth)
  end


  test "project_id can be overridden in config" do
    project = "different"
    Application.put_env(:huth, :project_id, project, persistent: true)
    Application.stop(:huth)

    Application.start(:huth)
    assert {:ok, project} == Config.get(:project_id)

    Application.put_env(:huth, :project_id, nil, persistent: true)
    Application.stop(:huth)
    Application.start(:huth)
  end

  test "the config_module is allowed to override config" do
    Application.put_env(:huth, :config_module, Huth.TestConfigMod)
    Application.stop(:huth)

    Application.start(:huth)
    assert {:ok, :val} == Huth.Config.get(:actor_email)

    Application.delete_env(:huth, :config_module)
    Application.stop(:huth)
    Application.start(:huth)
  end
end

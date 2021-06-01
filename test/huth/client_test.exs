defmodule Huth.ClientTest do
  use ExUnit.Case
  alias Huth.Client
  alias Huth.Token

  setup do
    bypass = Bypass.open()
    bypass_url = "http://localhost:#{bypass.port}"
    Application.put_env(:huth, :endpoint, bypass_url)
    Application.put_env(:huth, :metadata_url, bypass_url)
    {:ok, bypass: bypass}
  end


  test "we call the API with the correct jwt data and generate a token", %{bypass: bypass} do
    token_response = %{
      "access_token" => "CgB6e3x9G+1agfdwNS+9hJSxFQgkqx6EdGAmLdGQ3I2NndffsHGCzWU9vuOJVrJ9PlJcqY2JYuhtGA+Zjr2gaRiO",
      "token_type" => "Bearer",
      "expires_in" => 3600
    }

    scope = "prediction"

    Bypass.expect(bypass, fn conn ->
      assert "/oauth2/v2/token" == conn.request_path
      assert "POST" == conn.method

      {:ok, body, _conn} = Plug.Conn.read_body(conn)
      assert String.length(body) > 0

      Plug.Conn.resp(conn, 201, Jason.encode!(token_response))
    end)

    {:ok, data} = Client.get_access_token(scope)

    at = token_response["access_token"]
    tt = token_response["token_type"]

    assert %Token{token: ^at, type: ^tt, expires: _exp} = data
  end

  test "When authentication fails, warn the user of the issue", %{bypass: bypass} do
    token_response = %{
      "error" => "deleted_client",
      "error_description" => "The OAuth client was deleted."
    }

    scope = "prediction"

    Bypass.expect(bypass, fn conn ->
      assert "/oauth2/v2/token" == conn.request_path
      assert "POST" == conn.method

      {:ok, body, _conn} = Plug.Conn.read_body(conn)
      assert String.length(body) > 0

      Plug.Conn.resp(conn, 401, Jason.encode!(token_response))
    end)

    {:error, data} = Client.get_access_token(scope)

    assert data =~ "Could not retrieve token, response:"
  end

  test "returns {:error, err} when HTTP call fails hard" do
    old_url = Application.get_env(:huth, :endpoint)
    Application.put_env(:huth, :endpoint, "nnnnnopelkjlkj.nope")
    assert {:error, _} = Client.get_access_token("my-scope")
    Application.put_env(:huth, :endpoint, old_url)
  end
end

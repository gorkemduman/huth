defmodule Huth.Client do
  alias Huth.Config
  alias Huth.Token

  @moduledoc """
  `Huth.Client` is the module through which all interaction with Huawei's APIs flows.

  ## Available Options

  The first parameter is either the token scopes or a tuple of the service
  account client email and its scopes.

  See
  [Huawei's Documentation](https://developer.huawei.com/consumer/en/doc/development/HMSCore-Guides-V5/open-platform-oauth-0000001053629189-V5#EN-US_TOPIC_0000001053629189__section12493191334711)
  for more details.

  """

  @doc """
  *Note:* Most often, you'll want to use `Huth.Token.for_scope/1` instead of this method.
  As the docs for `Huth.Token.for_scope/1` note, it will return a cached token if one
  already exists, thus saving you the cost of a round-trip to the server to generate a
  new token.

  `Huth.Client.get_access_token/1`, on the other hand will always hit the server to
  retrieve a new token.
  """

  def get_access_token(scope), do: get_access_token({:default, scope}, [])

  def get_access_token(scope, opts) when is_binary(scope) and is_list(opts) do
    get_access_token({:default, scope}, opts)
  end

  def get_access_token({account, scope}, opts) when is_binary(scope) and is_list(opts) do
    {:ok, token_source} = Config.get(account, :token_source)
    get_access_token(token_source, {account, scope}, opts)
  end

  @doc false
  def get_access_token(source, info, opts \\ [])
  # Fetch an access token from Huawei's metadata service for applications running
  # on Huawei's Cloud platform.
  def get_access_token(type, scope, opts) when is_atom(type) and is_binary(scope) do
    get_access_token(type, {:default, scope}, opts)
  end

  # Fetch an access token from Huawei's OAuth service using client credential
  def get_access_token(:oauth_client_credential, {account, scope}, _opts) do
    {:ok, grand_type} = Config.get(:grand_type)
    {:ok, client_id} = Config.get(:client_id)
    {:ok, client_secret} = Config.get(:client_secret)
    endpoint = Application.get_env(:huth, :endpoint, "https://oauth-login.cloud.huawei.com")
    url = "#{endpoint}/oauth2/v2/token"

    body =
      {:form,
        [
          grant_type: grand_type,
          client_id: client_id,
          client_secret: client_secret
        ]}

    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]

    HTTPoison.post(url, body, headers)
    |> handle_response({account, scope})
  end

  defp handle_response(resp, opts, sub \\ nil)

  defp handle_response({:ok, %{body: body, status_code: code}}, {account, scope}, sub)
       when code in 200..299,
       do: {:ok, Token.from_response_json({account, scope}, sub, body)}

  defp handle_response({:ok, %{body: body}}, _scope, _sub),
    do: {:error, "Could not retrieve token, response: #{body}"}

  defp handle_response(other, _scope, _sub), do: other
end

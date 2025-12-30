defmodule Mix.Tasks.TestProxy do
  @moduledoc """
  Test a single proxy with verbose output

  Usage: mix test_proxy <ip:port>
  """
  use Mix.Task

  require Logger

  @shortdoc "Test a single proxy with verbose output"
  def run(args) do
    # Start dependencies
    {:ok, _} = Application.ensure_all_started(:proxy_ips)

    proxy =
      case args do
        [p] -> p
        [] -> fetch_sample_proxy()
      end

    IO.puts("\n=== Testing proxy: #{proxy} ===\n")

    [ip, port] = String.split(proxy, ":")

    opts = [
      connect_options: [
        proxy: {:http, String.trim(ip), String.to_integer(String.trim(port)), []},
        transport_opts: [
          timeout: 5_000,
          inet6: false,
          verify: :verify_none
        ]
      ],
      receive_timeout: 15_000,
      retry: false,
      max_redirects: 0
    ]

    IO.puts("Request options:")
    IO.inspect(opts, pretty: true)
    IO.puts("")

    IO.puts("Making request to https://httpbin.org/ip...")
    result = Req.get("https://httpbin.org/ip", opts)

    IO.puts("\nResult:")

    case result do
      {:ok, %{status: 200} = response} ->
        IO.puts("✓ SUCCESS - Status 200")
        IO.puts("Body: #{inspect(response.body)}")

      {:ok, %{status: status} = response} ->
        IO.puts("✗ Invalid status: #{status}")
        IO.puts("Body: #{inspect(response.body)}")
        IO.puts("Headers: #{inspect(response.headers)}")

      {:error, error} ->
        IO.puts("✗ ERROR:")
        IO.inspect(error, pretty: true, limit: :infinity)
    end
  end

  defp fetch_sample_proxy do
    IO.puts("No proxy provided, fetching a sample proxy...")

    {:ok, response} =
      :httpc.request(
        :get,
        {~c"https://raw.githubusercontent.com/vakhov/fresh-proxy-list/master/http.txt", []},
        [],
        []
      )

    {{_, 200, _}, _, body} = response
    proxy = body |> to_string() |> String.split("\n", trim: true) |> hd()
    IO.puts("Using sample proxy: #{proxy}\n")
    proxy
  end
end

defmodule ProxyIps.Tester do
  @moduledoc """
  Tests proxies to verify they are working
  """

  require Logger

  alias ProxyIps.{Cache, Config, Scraper}

  @test_url "https://httpbin.org/ip"

  @doc """
  Tests multiple proxies in parallel using Flow with caching
  Proxies are maps with %{proxy: "ip:port", host: "ip", port: "port", source: "url"}
  """
  @spec test_proxies([Scraper.proxy_map()], atom()) :: [Scraper.proxy_map()]
  def test_proxies(proxies, protocol) do
    Logger.info("Testing #{length(proxies)} #{protocol} proxies...")

    # Load cached results
    cached_results = Cache.load_cached_results(protocol)
    Logger.info("Loaded #{map_size(cached_results)} cached results for #{protocol}")

    # Separate cached vs needs testing
    {cached_proxies, needs_testing} =
      Enum.split_with(proxies, fn proxy_map ->
        Map.has_key?(cached_results, proxy_map.proxy)
      end)

    # Extract working proxies from cache
    working_from_cache =
      cached_proxies
      |> Enum.filter(fn proxy_map ->
        result = cached_results[proxy_map.proxy]
        result["working"] == true
      end)

    Logger.info(
      "Skipping #{length(cached_proxies)} proxies already tested (#{length(working_from_cache)} working from cache)"
    )

    Logger.info("Testing #{length(needs_testing)} new/expired #{protocol} proxies...")

    # Test only new proxies
    newly_working =
      needs_testing
      |> Flow.from_enumerable(max_demand: 10, stages: 8)
      |> Flow.map(fn proxy_map ->
        case test_proxy_with_cache(proxy_map.proxy, protocol) do
          :ok ->
            Logger.debug("✓ #{protocol} proxy working: #{proxy_map.proxy}")
            proxy_map

          {:error, reason} ->
            Logger.debug("✗ #{protocol} proxy failed: #{proxy_map.proxy} - #{inspect(reason)}")
            nil
        end
      end)
      |> Flow.reject(&is_nil/1)
      |> Enum.to_list()

    # Combine results
    all_working = working_from_cache ++ newly_working

    Logger.info(
      "Found #{length(all_working)} total working #{protocol} proxies (#{length(working_from_cache)} cached + #{length(newly_working)} newly tested)"
    )

    all_working
  end

  @doc """
  Tests a single proxy string and caches the result
  """
  @spec test_proxy_with_cache(String.t(), atom()) ::
          :ok | {:error, :timeout | :connection_refused | :invalid_response | term()}
  def test_proxy_with_cache(proxy_string, protocol) do
    result = test_proxy(proxy_string, protocol)

    # Cache the result
    working? = result == :ok
    Cache.put_result(proxy_string, protocol, working?)

    result
  end

  @doc """
  Tests a single proxy string
  """
  @spec test_proxy(String.t(), atom()) ::
          :ok | {:error, :timeout | :connection_refused | :invalid_response | term()}
  def test_proxy(proxy_string, protocol) do
    try do
      case protocol do
        :http -> test_http_proxy(proxy_string)
        :https -> test_https_proxy(proxy_string)
        :socks4 -> test_socks_proxy(proxy_string, :socks4)
        :socks5 -> test_socks_proxy(proxy_string, :socks5)
      end
    rescue
      e ->
        Logger.debug("Exception testing #{proxy_string}: #{inspect(e)}")
        {:error, {:exception, e}}
    catch
      :exit, reason ->
        Logger.debug("Exit testing #{proxy_string}: #{inspect(reason)}")
        {:error, {:exit, reason}}
    end
  end

  defp test_http_proxy(proxy) do
    [ip, port] = String.split(proxy, ":")

    opts = [
      finch: ProxyIps.Finch,
      connect_options: [
        proxy: {:http, ip, String.to_integer(port), []}
      ],
      receive_timeout: Config.proxy_test_timeout(),
      retry: false,
      max_redirects: 0
    ]

    case Req.get(@test_url, opts) do
      {:ok, %{status: 200}} ->
        :ok

      {:ok, %{status: status}} ->
        {:error, {:invalid_response, status}}

      {:error, %{reason: :timeout}} ->
        {:error, :timeout}

      {:error, %{reason: :econnrefused}} ->
        {:error, :connection_refused}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp test_https_proxy(proxy) do
    [ip, port] = String.split(proxy, ":")

    opts = [
      finch: ProxyIps.Finch,
      connect_options: [
        proxy: {:https, ip, String.to_integer(port), []}
      ],
      receive_timeout: Config.proxy_test_timeout(),
      retry: false,
      max_redirects: 0
    ]

    case Req.get(@test_url, opts) do
      {:ok, %{status: 200}} ->
        :ok

      {:ok, %{status: status}} ->
        {:error, {:invalid_response, status}}

      {:error, %{reason: :timeout}} ->
        {:error, :timeout}

      {:error, %{reason: :econnrefused}} ->
        {:error, :connection_refused}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp test_socks_proxy(proxy, version) do
    # For SOCKS proxies, we'll use a system curl command since Req/Mint don't have built-in SOCKS support
    [ip, port] = String.split(proxy, ":")

    socks_flag =
      case version do
        :socks4 -> "--socks4"
        :socks5 -> "--socks5"
      end

    timeout_seconds = Config.proxy_test_timeout() |> div(1000) |> to_string()

    case System.cmd("curl", [
           "--max-time",
           timeout_seconds,
           "--connect-timeout",
           "5",
           "--silent",
           "-4",
           socks_flag,
           "#{ip}:#{port}",
           @test_url
         ]) do
      {_output, 0} ->
        :ok

      {_output, 7} ->
        {:error, :connection_refused}

      {_output, 28} ->
        {:error, :timeout}

      {_output, exit_code} ->
        {:error, {:curl_error, exit_code}}
    end
  rescue
    e -> {:error, {:curl_exception, e}}
  end
end

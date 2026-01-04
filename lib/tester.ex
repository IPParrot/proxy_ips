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

    total_to_test = length(needs_testing)

    if total_to_test > 0 do
      Logger.info("Testing #{total_to_test} new/expired #{protocol} proxies...")

      # Start progress tracker
      {:ok, _pid} = ProxyIps.Progress.start_link(total_to_test, protocol)

      # Test only new proxies
      newly_working =
        needs_testing
        |> Flow.from_enumerable(max_demand: 30, stages: 24)
        |> Flow.map(fn proxy_map ->
          result =
            case test_proxy_with_cache(proxy_map.proxy, protocol) do
              :ok ->
                proxy_map

              {:error, _reason} ->
                nil
            end

          # Increment progress counter
          ProxyIps.Progress.increment(protocol)
          result
        end)
        |> Flow.reject(&is_nil/1)
        |> Enum.to_list()

      # Final progress report
      ProxyIps.Progress.final_report(protocol)
      ProxyIps.Progress.stop(protocol)

      # Combine results
      all_working = working_from_cache ++ newly_working

      Logger.info(
        "Found #{length(all_working)} total working #{protocol} proxies (#{length(working_from_cache)} cached + #{length(newly_working)} newly tested)"
      )

      all_working
    else
      Logger.info("No new proxies to test, using #{length(working_from_cache)} from cache")
      working_from_cache
    end
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
        {:error, {:exception, e}}
    catch
      :exit, reason ->
        {:error, {:exit, reason}}
    end
  end

  defp test_http_proxy(proxy) do
    [ip, port] = String.split(proxy, ":")

    proxy_url = "http://#{String.trim(ip)}:#{String.trim(port)}"

    req = %{
      url: @test_url,
      method: :get,
      proxy: proxy_url,
      connecttimeout_ms: Config.proxy_connect_timeout(),
      timeout_ms: Config.proxy_test_timeout(),
      ssl_verifyhost: false,
      ssl_verifypeer: false
    }

    case :katipo.req(:katipo_pool, req) do
      {:ok, %{status: 200}} ->
        :ok

      {:ok, %{status: status}} ->
        {:error, {:invalid_response, status}}

      {:error, %{code: :operation_timedout}} ->
        {:error, :timeout}

      {:error, %{code: :couldnt_connect}} ->
        {:error, :connection_refused}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp test_https_proxy(proxy) do
    [ip, port] = String.split(proxy, ":")

    proxy_url = "http://#{String.trim(ip)}:#{String.trim(port)}"

    req = %{
      url: @test_url,
      method: :get,
      proxy: proxy_url,
      connecttimeout_ms: Config.proxy_connect_timeout(),
      timeout_ms: Config.proxy_test_timeout(),
      ssl_verifyhost: false,
      ssl_verifypeer: false
    }

    case :katipo.req(:katipo_pool, req) do
      {:ok, %{status: 200}} ->
        :ok

      {:ok, %{status: status}} ->
        {:error, {:invalid_response, status}}

      {:error, %{code: :operation_timedout}} ->
        {:error, :timeout}

      {:error, %{code: :couldnt_connect}} ->
        {:error, :connection_refused}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp test_socks_proxy(proxy, version) do
    [ip, port] = String.split(proxy, ":")

    # Build SOCKS proxy URL
    proxy_scheme =
      case version do
        :socks4 -> "socks4"
        :socks5 -> "socks5"
      end

    proxy_url = "#{proxy_scheme}://#{String.trim(ip)}:#{String.trim(port)}"

    # Build Katipo request
    req = %{
      url: @test_url,
      method: :get,
      proxy: proxy_url,
      connecttimeout_ms: Config.proxy_connect_timeout(),
      timeout_ms: Config.proxy_test_timeout(),
      ssl_verifyhost: false,
      ssl_verifypeer: false
    }

    case :katipo.req(:katipo_pool, req) do
      {:ok, %{status: 200}} ->
        :ok

      {:ok, %{status: status}} ->
        {:error, {:invalid_response, status}}

      {:error, %{code: :operation_timedout}} ->
        {:error, :timeout}

      {:error, %{code: :couldnt_connect}} ->
        {:error, :connection_refused}

      {:error, reason} ->
        {:error, reason}
    end
  end
end

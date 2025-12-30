defmodule ProxyIps.Scraper do
  @moduledoc """
  Scrapes proxy lists from various sources
  """

  require Logger

  alias ProxyIps.{Cache, Config}

  @type proxy_map :: %{proxy: String.t(), host: String.t(), port: String.t(), source: String.t()}

  @doc """
  Fetches proxies from a single URL (with caching)
  """
  @spec fetch_from_url(String.t()) :: {:ok, [proxy_map()]} | {:error, term()}
  def fetch_from_url(url) do
    fetch_fn = fn ->
      Logger.info("Downloading proxies from: #{url}")

      req = %{
        url: url,
        method: :get,
        timeout_ms: Config.source_fetch_timeout(),
        connecttimeout_ms: 5_000,
        ssl_verifypeer: false
      }

      case :katipo.req(:katipo_pool, req) do
        {:ok, %{status: 200, body: body}} ->
          {:ok, body}

        {:ok, %{status: status}} when status >= 400 and status < 500 ->
          Logger.warning("Failed to fetch from #{url}: HTTP #{status} (client error)")
          {:error, {:http_client_error, status}}

        {:ok, %{status: status}} when status >= 500 ->
          Logger.warning("Failed to fetch from #{url}: HTTP #{status} (server error)")
          {:error, {:http_server_error, status}}

        {:ok, %{status: status}} ->
          Logger.warning("Failed to fetch from #{url}: HTTP #{status}")
          {:error, {:http_error, status}}

        {:error, %{code: :operation_timedout}} ->
          Logger.warning("Timeout fetching from #{url}")
          {:error, :timeout}

        {:error, %{code: :couldnt_connect}} ->
          Logger.warning("Connection refused for #{url}")
          {:error, :connection_refused}

        {:error, reason} ->
          Logger.warning("Error fetching from #{url}: #{inspect(reason)}")
          {:error, reason}
      end
    end

    case Cache.get_source(url, fetch_fn) do
      {:ok, body} ->
        proxies = parse_proxy_list(body, url)
        Logger.info("Fetched #{length(proxies)} proxies from #{url}")
        {:ok, proxies}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Fetches proxies from multiple URLs in parallel using Flow
  Returns list of proxy maps with source information
  """
  @spec fetch_from_sources([String.t()], atom()) :: [proxy_map()]
  def fetch_from_sources(urls, protocol) do
    Logger.info("Starting to fetch #{protocol} proxies from #{length(urls)} sources")

    proxies =
      urls
      |> Flow.from_enumerable(max_demand: 5, stages: 3)
      |> Flow.map(fn url ->
        case fetch_from_url(url) do
          {:ok, proxies} -> proxies
          {:error, _} -> []
        end
      end)
      |> Flow.flat_map(& &1)
      |> Enum.to_list()
      |> deduplicate_proxies()

    Logger.info("Fetched total #{length(proxies)} unique #{protocol} proxies")
    proxies
  end

  defp deduplicate_proxies(proxy_list) do
    # Deduplicate by proxy string, keeping first occurrence (with its source)
    proxy_list
    |> Enum.reduce(%{}, fn proxy, acc ->
      Map.put_new(acc, proxy.proxy, proxy)
    end)
    |> Map.values()
  end

  @doc """
  Parses a proxy list text into proxy maps with source information
  """
  @spec parse_proxy_list(String.t(), String.t()) :: [proxy_map()]
  def parse_proxy_list(text, source) when is_binary(text) do
    text
    |> String.split(["\n", "\r\n", "\r"], trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == "" or String.starts_with?(&1, "#")))
    |> Enum.filter(&valid_proxy_format?/1)
    |> Enum.map(fn proxy ->
      [host, port] = String.split(proxy, ":")
      %{proxy: proxy, host: host, port: port, source: source}
    end)
  end

  @doc """
  Validates proxy format (IP:PORT)
  """
  @spec valid_proxy_format?(String.t()) :: boolean()
  def valid_proxy_format?(proxy) do
    case String.split(proxy, ":") do
      [ip, port] ->
        valid_ip?(ip) and valid_port?(port)

      _ ->
        false
    end
  end

  defp valid_ip?(ip) do
    case :inet.parse_address(String.to_charlist(ip)) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  defp valid_port?(port) do
    case Integer.parse(port) do
      {port_num, ""} when port_num > 0 and port_num <= 65535 -> true
      _ -> false
    end
  end
end

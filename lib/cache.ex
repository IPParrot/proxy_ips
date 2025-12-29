defmodule ProxyIps.Cache do
  @moduledoc """
  Handles caching of proxy sources and test results
  """

  require Logger

  alias ProxyIps.Config

  @type fetch_fn :: (-> {:ok, String.t()} | {:error, term()})
  @type cache_result :: {:ok, term()} | {:error, :not_found | :expired | :invalid_json | term()}

  @cache_dir ".cache"
  @sources_cache_dir Path.join(@cache_dir, "sources")
  @results_cache_dir Path.join(@cache_dir, "results")

  @spec init() :: :ok
  def init do
    File.mkdir_p!(@sources_cache_dir)
    File.mkdir_p!(@results_cache_dir)
    :ok
  end

  @doc """
  Get cached source or download if expired/missing
  Returns {:ok, content} or {:error, reason}
  """
  @spec get_source(String.t(), fetch_fn()) :: {:ok, String.t()} | {:error, term()}
  def get_source(url, fetch_fn) do
    cache_key = url_to_cache_key(url)
    cache_path = Path.join(@sources_cache_dir, cache_key)

    case read_cached_file(cache_path, hours_to_ms(Config.source_cache_ttl_hours())) do
      {:ok, content} ->
        Logger.debug("Using cached source: #{url}")
        {:ok, content}

      {:error, _} ->
        Logger.debug("Cache miss or expired for: #{url}")

        case fetch_fn.() do
          {:ok, content} ->
            write_cache_file(cache_path, content)
            {:ok, content}

          {:error, reason} = error ->
            # Try to use stale cache as fallback
            case File.read(cache_path) do
              {:ok, stale_content} ->
                Logger.warning(
                  "Using stale cache for #{url} due to fetch error: #{inspect(reason)}"
                )

                {:ok, stale_content}

              _ ->
                error
            end
        end
    end
  end

  @doc """
  Get cached proxy test result
  Returns {:ok, result} | {:error, :not_found} | {:error, :expired}
  """
  @spec get_result(String.t(), atom()) :: cache_result()
  def get_result(proxy, protocol) do
    cache_key = result_cache_key(proxy, protocol)
    cache_path = Path.join(@results_cache_dir, cache_key)

    case read_cached_json(cache_path, hours_to_ms(Config.result_cache_ttl_hours())) do
      {:ok, result} ->
        Logger.debug("Cache hit for #{protocol}://#{proxy}")
        {:ok, result}

      error ->
        error
    end
  end

  @doc """
  Save proxy test result to cache
  """
  @spec put_result(String.t(), atom(), boolean()) :: :ok
  def put_result(proxy, protocol, working?) do
    cache_key = result_cache_key(proxy, protocol)
    cache_path = Path.join(@results_cache_dir, cache_key)

    result = %{
      proxy: proxy,
      protocol: to_string(protocol),
      working: working?,
      tested_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    write_cache_json(cache_path, result)
  end

  @doc """
  Load all cached results for a protocol
  Returns map of proxy => result
  """
  @spec load_cached_results(atom()) :: %{String.t() => map()}
  def load_cached_results(protocol) do
    pattern = Path.join(@results_cache_dir, "#{protocol}_*.json")

    pattern
    |> Path.wildcard()
    |> Enum.map(fn path ->
      case read_cached_json(path, hours_to_ms(Config.result_cache_ttl_hours())) do
        {:ok, result} -> {result["proxy"], result}
        {:error, _} -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Map.new()
  end

  # Private helpers

  defp url_to_cache_key(url) do
    # Use SHA256 hash to avoid filesystem issues with long/special URLs
    # and prevent any potential injection attacks
    hash = :crypto.hash(:sha256, url) |> Base.encode16(case: :lower)
    # Include first 32 chars of sanitized URL for debugging, then hash
    sanitized =
      url
      |> String.replace(~r{^https?://}, "")
      |> String.replace(~r{[^a-zA-Z0-9_\-.]}, "_")
      |> String.slice(0, 32)

    "#{sanitized}_#{hash}.txt"
  end

  defp result_cache_key(proxy, protocol) do
    # Use hash for consistency and safety
    hash = :crypto.hash(:sha256, proxy) |> Base.encode16(case: :lower)
    # Keep sanitized proxy for debugging (IP:PORT format is already safe)
    sanitized = String.replace(proxy, ":", "_")
    "#{protocol}_#{sanitized}_#{String.slice(hash, 0, 16)}.json"
  end

  defp read_cached_file(path, max_age_ms) do
    with {:ok, stat} <- File.stat(path),
         true <- cache_valid?(stat, max_age_ms),
         {:ok, content} <- File.read(path) do
      {:ok, content}
    else
      false -> {:error, :expired}
      {:error, :enoent} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  defp read_cached_json(path, max_age_ms) do
    case read_cached_file(path, max_age_ms) do
      {:ok, content} ->
        try do
          data = JSON.decode!(content)
          {:ok, data}
        rescue
          _ -> {:error, :invalid_json}
        end

      error ->
        error
    end
  end

  defp write_cache_file(path, content) do
    File.write!(path, content)
  end

  defp write_cache_json(path, data) do
    content = JSON.encode!(data)
    File.write!(path, content)
  end

  defp cache_valid?(stat, max_age_ms) do
    now = System.system_time(:millisecond)
    file_time = stat.mtime |> datetime_to_ms()
    age_ms = now - file_time

    age_ms < max_age_ms
  end

  defp datetime_to_ms({{year, month, day}, {hour, minute, second}}) do
    {:ok, datetime} = NaiveDateTime.new(year, month, day, hour, minute, second)
    datetime |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix(:millisecond)
  end

  defp hours_to_ms(hours), do: hours * 60 * 60 * 1000
end

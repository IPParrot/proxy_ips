defmodule ProxyIps.CsvWriter do
  @moduledoc """
  Generates CSV output for all proxies
  """

  alias ProxyIps.Scraper

  @type csv_stats :: %{total: non_neg_integer(), counts: %{atom() => non_neg_integer()}}

  @doc """
  Generates proxies.csv with columns: host,port,protocol,source
  Takes a map of %{protocol => [proxy_maps]}
  """
  @spec generate_csv(%{atom() => [Scraper.proxy_map()]}, String.t()) :: csv_stats()
  def generate_csv(all_working_proxies, output_path) do
    # Flatten all proxies with protocol info
    rows =
      all_working_proxies
      |> Enum.flat_map(fn {protocol, proxy_list} ->
        Enum.map(proxy_list, fn proxy_map ->
          %{
            host: proxy_map.host,
            port: proxy_map.port,
            protocol: to_string(protocol),
            source: proxy_map.source
          }
        end)
      end)
      |> Enum.sort_by(fn row -> {row.protocol, row.host, row.port} end)

    # Generate CSV content
    header = "host,port,protocol,source\n"

    body =
      rows
      |> Enum.map(fn row ->
        [
          csv_escape(row.host),
          csv_escape(row.port),
          csv_escape(row.protocol),
          csv_escape(row.source)
        ]
        |> Enum.join(",")
      end)
      |> Enum.join("\n")

    csv_content = header <> body <> "\n"

    # Write to file
    File.write!(output_path, csv_content)

    # Return stats
    %{
      total: length(rows),
      counts: count_by_protocol(all_working_proxies)
    }
  end

  @doc """
  Escapes a CSV field value
  Quotes the field if it contains comma, quote, or newline
  """
  @spec csv_escape(String.t()) :: String.t()
  def csv_escape(value) when is_binary(value) do
    if String.contains?(value, [",", "\"", "\n", "\r"]) do
      escaped = String.replace(value, "\"", "\"\"")
      "\"#{escaped}\""
    else
      value
    end
  end

  defp count_by_protocol(all_working_proxies) do
    all_working_proxies
    |> Enum.map(fn {protocol, proxies} ->
      {protocol, length(proxies)}
    end)
    |> Map.new()
  end
end

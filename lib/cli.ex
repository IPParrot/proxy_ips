defmodule ProxyIps.CLI do
  @moduledoc """
  Main CLI module for the proxy scraper escript
  """

  require Logger

  alias ProxyIps.{Sources, Scraper, Tester, Cache, CsvWriter}

  @output_dir "proxies"

  @spec main([String.t()]) :: :ok
  def main(_args) do
    Logger.configure(level: :info)
    IO.puts("Starting proxy collection and testing...")

    # Initialize cache system
    Cache.init()

    # Ensure output directory exists
    File.mkdir_p!(@output_dir)

    # Process each protocol
    all_working_proxies =
      Sources.all_sources()
      |> Enum.map(fn {protocol, sources} ->
        IO.puts("\n=== Processing #{String.upcase(to_string(protocol))} proxies ===")

        # Fetch proxies
        proxies = Scraper.fetch_from_sources(sources, protocol)
        IO.puts("Found #{length(proxies)} unique proxies")

        # Test proxies
        working_proxies = Tester.test_proxies(proxies, protocol)
        IO.puts("✓ #{length(working_proxies)} working proxies")

        # Save results
        save_proxies(working_proxies, protocol)

        {protocol, working_proxies}
      end)
      |> Map.new()

    # Generate summary files
    generate_summary_files(all_working_proxies)

    IO.puts("\n=== Summary ===")
    IO.puts("HTTP: #{length(all_working_proxies[:http])} working")
    IO.puts("HTTPS: #{length(all_working_proxies[:https])} working")
    IO.puts("SOCKS4: #{length(all_working_proxies[:socks4])} working")
    IO.puts("SOCKS5: #{length(all_working_proxies[:socks5])} working")
    IO.puts("\nResults saved to ./#{@output_dir}/")

    :ok
  end

  defp save_proxies(proxy_maps, protocol) do
    filename = Path.join(@output_dir, "#{protocol}.txt")
    # Extract proxy strings from proxy maps
    proxy_strings = Enum.map(proxy_maps, fn p -> p.proxy end)
    content = Enum.join(proxy_strings, "\n")
    File.write!(filename, content <> "\n")
    IO.puts("Saved to #{filename}")
  end

  defp generate_summary_files(all_working_proxies) do
    # Generate ips.txt with all IPs
    all_ips =
      all_working_proxies
      |> Enum.flat_map(fn {_protocol, proxy_maps} -> proxy_maps end)
      |> Enum.map(fn proxy_map -> proxy_map.host end)
      |> Enum.uniq()
      |> Enum.sort()

    ips_file = Path.join(@output_dir, "ips.txt")
    File.write!(ips_file, Enum.join(all_ips, "\n") <> "\n")
    IO.puts("Generated #{ips_file} with #{length(all_ips)} unique IPs")

    # Generate updated_at.txt
    {:ok, now} = DateTime.now("Etc/UTC")
    timestamp = DateTime.to_string(now)
    updated_at_file = Path.join(@output_dir, "updated_at.txt")
    File.write!(updated_at_file, timestamp <> "\n")
    IO.puts("Updated #{updated_at_file}")

    # Generate proxies.csv
    csv_file = Path.join(@output_dir, "proxies.csv")
    csv_stats = CsvWriter.generate_csv(all_working_proxies, csv_file)

    IO.puts(
      "Generated #{csv_file} with #{csv_stats.total} proxies (#{inspect(csv_stats.counts)})"
    )
  end
end

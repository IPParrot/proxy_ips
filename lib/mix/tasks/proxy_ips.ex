defmodule Mix.Tasks.ProxyIps do
  @moduledoc """
  Run the proxy scraper and tester

  Usage:
      mix proxy_ips

  This task fetches proxy lists from multiple sources, tests each proxy for
  connectivity, and saves working proxies to text files in the `proxies/` directory.
  """
  use Mix.Task

  @shortdoc "Scrape and test proxy lists"

  @impl Mix.Task
  def run(_args) do
    # Start the application (includes Finch and Katipo)
    {:ok, _} = Application.ensure_all_started(:proxy_ips)

    # Run the CLI logic
    ProxyIps.CLI.main([])
  end
end

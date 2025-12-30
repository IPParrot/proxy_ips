defmodule ProxyIps.MixProject do
  use Mix.Project

  def project do
    [
      app: :proxy_ips,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto, :inets, :ssl, :syntax_tools],
      mod: {ProxyIps.Application, []}
    ]
  end

  defp deps do
    [
      {:flow, "~> 1.2"},
      {:katipo, "~> 1.1"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Removed escript configuration - using Mix task instead to support Katipo NIF
  # defp escript do
  #   [main_module: ProxyIps.CLI]
  # end
end

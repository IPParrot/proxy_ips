defmodule ProxyIps.MixProject do
  use Mix.Project

  def project do
    [
      app: :proxy_ips,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto, :inets, :ssl],
      mod: {ProxyIps.Application, []}
    ]
  end

  defp deps do
    [
      {:req, "~> 0.5"},
      {:flow, "~> 1.2"}
    ]
  end

  defp escript do
    [main_module: ProxyIps.CLI]
  end
end

defmodule ProxyIps.Application do
  @moduledoc """
  OTP Application for ProxyIps with supervised HTTP connection pooling
  """

  use Application

  @impl true
  @spec start(Application.start_type(), term()) :: {:ok, pid()} | {:error, term()}
  def start(_type, _args) do
    # Start katipo application
    {:ok, _} = Application.ensure_all_started(:katipo)

    # Start katipo pool for SOCKS proxy testing
    pool_name = :katipo_pool
    pool_size = 100
    pool_opts = [pipelining: :nothing, max_total_connections: 100]
    {:ok, _} = :katipo_pool.start(pool_name, pool_size, pool_opts)

    children = [
      # Finch HTTP client with connection pooling
      {Finch,
       name: ProxyIps.Finch,
       pools: %{
         # Default pool for general HTTP requests
         :default => [
           size: 50,
           count: 8,
           protocols: [:http1]
         ],
         # Pool for proxy source fetching
         "https://raw.githubusercontent.com" => [
           size: 25,
           count: 4,
           protocols: [:http1]
         ],
         # Pool for proxy testing
         "https://httpbin.org" => [
           size: 100,
           count: 10,
           protocols: [:http1]
         ]
       }}
    ]

    opts = [strategy: :one_for_one, name: ProxyIps.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

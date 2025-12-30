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

    # Start katipo pool for all proxy testing
    pool_name = :katipo_pool
    pool_size = 100
    pool_opts = [pipelining: :nothing, max_total_connections: 100]
    {:ok, _} = :katipo_pool.start(pool_name, pool_size, pool_opts)

    # No supervision tree needed - katipo manages its own workers
    opts = [strategy: :one_for_one, name: ProxyIps.Supervisor]
    Supervisor.start_link([], opts)
  end
end

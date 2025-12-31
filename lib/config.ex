defmodule ProxyIps.Config do
  @moduledoc """
  Configuration management for ProxyIps
  """

  @default_proxy_test_timeout 3_000
  @default_proxy_connect_timeout 1_000
  @default_source_fetch_timeout 10_000
  @default_source_cache_ttl_hours 6
  @default_result_cache_ttl_hours 18

  @doc """
  Get proxy test timeout in milliseconds
  Default: 15,000ms (15 seconds)
  """
  @spec proxy_test_timeout() :: pos_integer()
  def proxy_test_timeout do
    Application.get_env(:proxy_ips, :proxy_test_timeout, @default_proxy_test_timeout)
  end

  @doc """
  Get proxy connection timeout in milliseconds
  Default: 5,000ms (5 seconds)
  """
  @spec proxy_connect_timeout() :: pos_integer()
  def proxy_connect_timeout do
    Application.get_env(:proxy_ips, :proxy_connect_timeout, @default_proxy_connect_timeout)
  end

  @doc """
  Get source fetch timeout in milliseconds
  Default: 10,000ms (10 seconds)
  """
  @spec source_fetch_timeout() :: pos_integer()
  def source_fetch_timeout do
    Application.get_env(:proxy_ips, :source_fetch_timeout, @default_source_fetch_timeout)
  end

  @doc """
  Get source cache TTL in hours
  Default: 6 hours
  """
  @spec source_cache_ttl_hours() :: pos_integer()
  def source_cache_ttl_hours do
    Application.get_env(:proxy_ips, :source_cache_ttl_hours, @default_source_cache_ttl_hours)
  end

  @doc """
  Get result cache TTL in hours
  Default: 18 hours
  """
  @spec result_cache_ttl_hours() :: pos_integer()
  def result_cache_ttl_hours do
    Application.get_env(:proxy_ips, :result_cache_ttl_hours, @default_result_cache_ttl_hours)
  end
end

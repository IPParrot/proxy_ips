defmodule ProxyIps.Progress do
  @moduledoc """
  Tracks and reports progress for proxy testing
  """
  use Agent

  require Logger

  @type state :: %{
          total: non_neg_integer(),
          completed: non_neg_integer(),
          start_time: integer(),
          last_report_count: non_neg_integer(),
          report_interval: non_neg_integer()
        }

  @doc """
  Start the progress tracker
  """
  @spec start_link(non_neg_integer()) :: {:ok, pid()}
  def start_link(total) do
    initial_state = %{
      total: total,
      completed: 0,
      start_time: System.monotonic_time(:second),
      last_report_count: 0,
      report_interval: max(div(total, 20), 1)
    }

    Agent.start_link(fn -> initial_state end, name: __MODULE__)
  end

  @doc """
  Increment the completed count and report progress if interval reached
  """
  @spec increment() :: :ok
  def increment do
    Agent.update(__MODULE__, fn state ->
      new_completed = state.completed + 1
      new_state = %{state | completed: new_completed}

      # Report progress every N completions (5% intervals)
      if new_completed - state.last_report_count >= state.report_interval do
        report_progress(new_state)
        %{new_state | last_report_count: new_completed}
      else
        new_state
      end
    end)
  end

  @doc """
  Get current progress statistics
  """
  @spec get_stats() :: map()
  def get_stats do
    Agent.get(__MODULE__, fn state ->
      elapsed = max(System.monotonic_time(:second) - state.start_time, 1)
      rate = state.completed / elapsed
      remaining = state.total - state.completed
      eta_seconds = if rate > 0, do: trunc(remaining / rate), else: 0

      %{
        total: state.total,
        completed: state.completed,
        percentage: if(state.total > 0, do: state.completed / state.total * 100, else: 0.0),
        elapsed_seconds: elapsed,
        rate_per_second: rate,
        remaining: remaining,
        eta_seconds: eta_seconds
      }
    end)
  end

  @doc """
  Report final statistics
  """
  @spec final_report() :: :ok
  def final_report do
    stats = get_stats()

    Logger.info("""
    ✓ Testing complete!
      Total: #{stats.total}
      Time: #{format_duration(stats.elapsed_seconds)}
      Rate: #{Float.round(stats.rate_per_second, 2)} proxies/sec
    """)

    :ok
  end

  @doc """
  Stop the progress tracker
  """
  @spec stop() :: :ok
  def stop do
    if Process.whereis(__MODULE__) do
      Agent.stop(__MODULE__)
    end

    :ok
  end

  # Private functions

  defp report_progress(state) do
    elapsed = max(System.monotonic_time(:second) - state.start_time, 1)
    percentage = if state.total > 0, do: state.completed / state.total * 100, else: 0.0
    rate = state.completed / elapsed
    remaining = state.total - state.completed
    eta_seconds = if rate > 0, do: trunc(remaining / rate), else: 0

    Logger.info(
      "Progress: #{state.completed}/#{state.total} (#{Float.round(percentage, 1)}%) | " <>
        "Rate: #{format_rate(rate)}/sec | " <>
        "ETA: #{format_duration(eta_seconds)}"
    )
  end

  defp format_rate(rate) when rate > 0, do: Float.round(rate, 2)
  defp format_rate(_rate), do: "0.00"

  defp format_duration(seconds) when seconds < 60 do
    "#{seconds}s"
  end

  defp format_duration(seconds) when seconds < 3600 do
    minutes = div(seconds, 60)
    secs = rem(seconds, 60)
    "#{minutes}m #{secs}s"
  end

  defp format_duration(seconds) do
    hours = div(seconds, 3600)
    minutes = div(rem(seconds, 3600), 60)
    "#{hours}h #{minutes}m"
  end
end

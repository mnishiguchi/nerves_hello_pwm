defmodule NervesHelloPwm.PwmScheduler do
  @moduledoc """
  Repeats the specified cycle. For faster PWM, please consider using better
  alternatives.

  ## Example

      NervesHelloPwm.PwmScheduler.start_link(%{
        id: 12,
        frequency: 1,
        duty_cycle: 50,
        on_fn: fn -> IO.puts("on") end,
        off_fn: fn -> IO.puts("off") end
      })

      # On/off rate: 80:20
      NervesHelloPwm.PwmScheduler.change_period(12, 1, 80)

      # Frequency: 2Hz (2x faster than 1Hz)
      NervesHelloPwm.PwmScheduler.change_period(12, 2, 80)

      # Stop the scheduler.
      NervesHelloPwm.PwmScheduler.stop(12)
      ** (EXIT from #PID<0.1202.0>) shell process exited with reason: shutdown

  """

  use GenServer, restart: :temporary
  require Logger

  # Used as a unique process name.
  def via_tuple(id) when is_number(id) do
    NervesHelloPwm.ProcessRegistry.via_tuple({__MODULE__, id})
  end

  def whereis(id) when is_number(id) do
    case NervesHelloPwm.ProcessRegistry.whereis_name({__MODULE__, id}) do
      :undefined -> nil
      pid -> pid
    end
  end

  def start_link(args)
      when is_map(args) and
             is_integer(args.id) and
             args.frequency in 1..100 and
             args.duty_cycle in 0..100 and
             is_function(args.on_fn) and
             is_function(args.off_fn) do
    GenServer.start_link(__MODULE__, args, name: via_tuple(args.id))
  end

  def change_period(id, frequency, duty_cycle)
      when frequency in 1..100 and duty_cycle in 0..100 do
    GenServer.call(via_tuple(id), {:change_period, frequency, duty_cycle})
  end

  def stop(id) when is_number(id) do
    with pid <- whereis(id), do: GenEvent.stop(pid, :shutdown)
  end

  @impl true
  def init(%{id: id, frequency: frequency, duty_cycle: duty_cycle} = args) do
    initial_state = Map.merge(args, calculate_period(frequency, duty_cycle))

    # Do nothing in duty_cycle if zero.
    unless initial_state.duty_cycle == 0, do: send(self(), :switch_on_and_schedule_next)

    Logger.info("#{__MODULE__}.init: #{id}")

    {:ok, initial_state}
  end

  @impl true
  def handle_call({:change_period, frequency, duty_cycle}, _from, %{id: id} = state) do
    Logger.info("#{__MODULE__}.change_period: #{id}")

    new_state = Map.merge(state, calculate_period(frequency, duty_cycle))
    {:reply, {:ok, self()}, new_state}
  end

  @impl true
  def handle_info(:switch_on_and_schedule_next, state) do
    %{off_fn: off_fn, on_fn: on_fn, on_time: on_time} = state

    # Switch on as long as on-time is a positive integer.
    if on_time == 0, do: off_fn.(), else: on_fn.()

    Process.send_after(self(), :switch_off_and_schedule_next, on_time)
    {:noreply, state}
  end

  @impl true
  def handle_info(:switch_off_and_schedule_next, %{off_fn: off_fn, off_time: off_time} = state) do
    off_fn.()
    Process.send_after(self(), :switch_on_and_schedule_next, off_time)
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, %{id: id, off_fn: off_fn} = state) do
    Logger.info("#{__MODULE__}.terminate: #{id}")

    off_fn.()
    {:noreply, state}
  end

  defp calculate_period(frequency, duty_cycle)
       when frequency in 1..100 and duty_cycle in 0..100 do
    period = round(1 / frequency * 1_000)

    # The on/off time must be of integer type.
    on_time = round(period * (duty_cycle / 100))
    off_time = period - on_time

    %{
      frequency: frequency,
      duty_cycle: duty_cycle,
      on_time: on_time,
      off_time: off_time
    }
  end
end

defmodule Bobochacha.SessionProcess do
  use GenServer, restart: :temporary

  alias Bobochacha.SessionConfig
  alias Nostrum.Voice

  def start_link(session_config) do
    GenServer.start_link(__MODULE__, session_config,
      name: Bobochacha.GuildRegistry.via_tuple(session_config)
    )
  end

  @impl GenServer
  def init(config) do
    set_up_voice(config)
    # This initial timer signal would kick off the pomo timer.
    {:ok, {:on_break, 0, config}, {:continue, :finish_init}}
  end

  @impl GenServer
  def terminate(:normal, {:on_break, _, session_config}),
    do: clean_up(session_config)

  @impl GenServer
  def handle_continue(:finish_init, state) do
    ping_myself_after(0)
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(
        :timer,
        last_state =
          {:on_break, iterations_elapsed,
           session_config = %SessionConfig{
             cycles_to_run: iterations_elapsed
           }}
      ) do
    announce_end(session_config)
    {:stop, :normal, last_state}
  end

  @impl GenServer
  def handle_cast(
        :timer,
        {:on_break, iterations_elapsed, session_config}
      ) do
    ping_myself_after(session_config.minutes_for_work)
    announce_work(session_config)
    {:noreply, {:working, iterations_elapsed + 1, session_config}}
  end

  @impl GenServer
  def handle_cast(
        :timer,
        {:working, iterations_elapsed,
         session_config = %SessionConfig{
           minutes_for_big_break: big_brek,
           minutes_for_small_break: smol_brek
         }}
      ) do
    cond do
      rem(iterations_elapsed, 4) == 0 ->
        ping_myself_after(big_brek)
        announce_big_break(session_config)

      true ->
        ping_myself_after(smol_brek)
        announce_small_break(session_config)
    end

    {:noreply, {:on_break, iterations_elapsed, session_config}}
  end

  @impl GenServer
  def handle_call(:state_for_testing, _from, state) do
    {:reply, state, state}
  end

  def state_for_testing(session_process) do
    GenServer.call(session_process, :state_for_testing)
  end

  def tick_timer_for_testing(session_process) do
    GenServer.cast(session_process, :timer)
  end

  defp set_up_voice(_session_config), do: "urmom"
  defp clean_up(_session_config), do: "urmom"

  defp ping_myself_after(mins), do: Process.send_after(self(), :timer, :timer.minutes(mins))

  defp announce_end(_session_config), do: "byebye"
  defp announce_work(_session_config), do: "workwork"

  defp announce_small_break(_session_config),
    do: "smolbrek"

  defp announce_big_break(_session_config),
    do: "bigbrek"
end

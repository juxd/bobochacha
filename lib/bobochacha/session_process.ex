defmodule Bobochacha.SessionProcess do
  alias Bobochacha.SessionConfig
  use GenServer, restart: :temporary

  def start_link({session_config, guild_id}) do
    GenServer.start_link(__MODULE__, session_config,
      name: Bobochacha.GuildRegistry.via_tuple(guild_id)
    )
  end

  @impl GenServer
  def init(config) do
    set_up_voice(Map.fetch(config, :voice_channel))
    # This initial timer signal would kick off the pomo timer.
    {:ok, {:on_break, 0, config}, {:continue, :finish_init}}
  end

  @impl GenServer
  def terminate(:normal, {:on_break, _, %SessionConfig{voice_channel: voice_channel}}),
    do: clean_up(voice_channel)

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
           %SessionConfig{
             text_channel: text_channel,
             voice_channel: voice_channel,
             cycles_to_run: iterations_elapsed
           }}
      ) do
    announce_end(text_channel, voice_channel)
    {:stop, :normal, last_state}
  end

  @impl GenServer
  def handle_cast(
        :timer,
        {:on_break, iterations_elapsed,
         config = %SessionConfig{
           text_channel: text_channel,
           voice_channel: voice_channel,
           minutes_for_work: minutes_for_work
         }}
      ) do
    ping_myself_after(minutes_for_work)
    announce_work(text_channel, voice_channel, minutes_for_work)
    {:noreply, {:working, iterations_elapsed + 1, config}}
  end

  @impl GenServer
  def handle_cast(
        :timer,
        {:working, iterations_elapsed,
         config = %SessionConfig{
           text_channel: text_channel,
           voice_channel: voice_channel,
           minutes_for_big_break: big_brek,
           minutes_for_small_break: smol_brek
         }}
      ) do
    cond do
      rem(iterations_elapsed, 4) == 0 ->
        ping_myself_after(big_brek)
        announce_big_break(text_channel, voice_channel, big_brek)

      true ->
        ping_myself_after(smol_brek)
        announce_small_break(text_channel, voice_channel, smol_brek)
    end

    {:noreply, {:on_break, iterations_elapsed, config}}
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

  defp set_up_voice(_voice_channel), do: "urmom"
  defp clean_up(_voice_channel), do: "urmom"

  defp ping_myself_after(mins), do: Process.send_after(self(), :timer, :timer.minutes(mins))

  defp announce_end(_text_channel, _voice_channel), do: "byebye"
  defp announce_work(_text_channel, _voice_channel, _minutes_for_work), do: "workwork"

  defp announce_small_break(_text_channel, _voice_channel, _minutes_for_small_break),
    do: "smolbrek"

  defp announce_big_break(_text_channel, _voice_channel, _minutes_for_big_break),
    do: "bigbrek"
end

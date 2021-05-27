defmodule Bobochacha.SessionProcess do
  alias Bobochacha.SessionConfig
  use GenServer, restart: :temporary

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(config) do
    set_up_voice(config[:voice_channel])
    # This initial timer signal would kick off the pomo timer.
    {:ok, {:on_break, 0, config}, {:continue, :finish_init}}
  end

  def terminate(:cycles_finished, %SessionConfig{voice_channel: voice_channel}),
    do: clean_up(voice_channel)

  def handle_continue(:finish_init, state) do
    ping_myself_after(0)
    {:no_reply, {state}}
  end

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
    {:stop, :cycles_finished, last_state}
  end

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
    {:no_reply, {:working, iterations_elapsed + 1, config}}
  end

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

    {:no_reply, {:on_break, iterations_elapsed, config}}
  end

  defp ping_myself_after(mins), do: Process.send_after(self(), :timer, :timer.minutes(mins))

  defp announce_end(_text_channel, _voice_channel), do: raise("IMPLEMENT ME")
  defp announce_work(_text_channel, _voice_channel, _minutes_for_work), do: raise("IMPLEMENT ME")

  defp announce_small_break(_text_channel, _voice_channel, _minutes_for_small_break),
    do: raise("IMPLEMENT ME")

  defp announce_big_break(_text_channel, _voice_channel, _minutes_for_big_break),
    do: raise("IMPLEMENT ME")
end

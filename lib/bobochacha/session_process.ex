defmodule Bobochacha.SessionProcess do
  use GenServer, restart: :temporary

  alias Bobochacha.SessionConfig
  alias Nostrum.Voice
  alias Nostrum.Api
  require Logger

  def start_link(session_config) do
    GenServer.start_link(__MODULE__, session_config,
      name: Bobochacha.GuildRegistry.via_tuple(session_config)
    )
  end

  @impl GenServer
  def init(session_config) do
    :ok = set_up_voice(session_config)
    # This initial timer signal would kick off the pomo timer.
    Logger.info("Session just initialised in #{session_config.guild_id}")
    {:ok, {:on_break, 0, session_config}, {:continue, :finish_init}}
  end

  defp wait_for_voice_connected(session_config) do
    if Voice.ready?(session_config.guild_id) do
      nil
    else
      wait_for_voice_connected(session_config)
    end
  end

  @impl GenServer
  def handle_continue(:finish_init, state = {_, _, session_config}) do
    wait_for_voice_connected(session_config)
    ping_myself_after(0)
    {:noreply, state}
  end

  @impl GenServer
  def terminate(_, {_, _, session_config}),
    do: clean_up(session_config)

  defmacrop log_error_or_return_if_ok(cond_, last_state, do: expr) do
    quote do
      case unquote(cond_) do
        :ok ->
          unquote(expr)

        {:error, error_msg} ->
          Logger.error("Error in session: #{inspect(error_msg)}")

          {:stop, :error, unquote(last_state)}
      end
    end
  end

  @impl GenServer
  def handle_info(
        :timer,
        last_state =
          {:on_break, iterations_elapsed,
           session_config = %SessionConfig{
             guild_id: guild_id,
             cycles_to_run: iterations_elapsed
           }}
      ) do
    Logger.info("Session ended for #{guild_id}")

    log_error_or_return_if_ok alert(session_config, "Pomo session finished!"), last_state do
      {:stop, :normal, last_state}
    end
  end

  @impl GenServer
  def handle_info(
        :timer,
        last_state = {:on_break, iterations_elapsed, session_config}
      ) do
    ping_myself_after(session_config.minutes_for_work)

    log_error_or_return_if_ok alert(session_config, "Time for work!"), last_state do
      {:noreply, {:working, iterations_elapsed + 1, session_config}}
    end
  end

  @impl GenServer
  def handle_info(
        :timer,
        last_state =
          {:working, iterations_elapsed,
           session_config = %SessionConfig{
             minutes_for_big_break: big_brek,
             minutes_for_small_break: smol_brek
           }}
      ) do
    break_size =
      cond do
        rem(iterations_elapsed, 4) == 0 ->
          ping_myself_after(big_brek)
          "big"

        true ->
          ping_myself_after(smol_brek)
          "small"
      end

    log_error_or_return_if_ok alert(session_config, "Time for a #{break_size} break!"),
                              last_state do
      {:noreply, {:on_break, iterations_elapsed, session_config}}
    end
  end

  @impl GenServer
  def handle_cast(:stop_session, last_state = {_, _, session_config}) do
    Logger.info(
      "early termination request for session running in guild #{session_config.guild_id}"
    )

    log_error_or_return_if_ok alert(session_config, "K, bye!"), last_state do
      {:stop, :normal, last_state}
    end
  end

  def stop_session(session_process) do
    GenServer.cast(session_process, :stop_session)
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

  defp set_up_voice(%SessionConfig{guild_id: guild_id, voice_channel: voice_channel}) do
    Voice.join_channel(guild_id, voice_channel)
  end

  defp clean_up(%SessionConfig{guild_id: guild_id}) do
    Voice.leave_channel(guild_id)
  end

  defp ping_myself_after(mins), do: Process.send_after(self(), :timer, :timer.minutes(mins))

  defp alert(config, message) do
    if Voice.ready?(config.guild_id) do
      with {:ok, _msg} <- Api.create_message(config.text_channel, message) do
        Voice.play(
          config.guild_id,
          File.read!(Application.fetch_env!(:bobochacha, :alert_file_path)),
          :pipe
        )
      end
    else
      {:error, "not in voice channel"}
    end
  end
end

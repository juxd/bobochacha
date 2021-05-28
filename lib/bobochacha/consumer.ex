defmodule Bobochacha.Consumer do
  use Nostrum.Consumer

  alias Nostrum.Api
  alias Nostrum.Cache.GuildCache

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  defp voice_channel_of(msg) do
    msg.guild_id
    |> GuildCache.get!()
    |> Map.get(:voice_states)
    |> Enum.find(%{}, fn v -> v.user_id == msg.author.id end)
    |> Map.get(:channel_id)
  end

  defp session_config_of(msg) do
    case voice_channel_of(msg) do
      nil ->
        :not_in_voice_channel

      voice_channel ->
        {:new_session,
         %Bobochacha.SessionConfig{
           guild_id: msg.guild_id,
           creator: msg.author,
           text_channel: msg.channel_id,
           voice_channel: voice_channel
         }}
    end
  end

  defp session_in_guild_of(msg) do
    case Bobochacha.GuildRegistry.lookup(msg.guild_id) do
      [] ->
        session_config_of(msg)

      [{session_process, session_config}] ->
        {:existing, session_process, session_config}
    end
  end

  defp handle_start_session(msg) do
    case session_in_guild_of(msg) do
      :not_in_voice_channel ->
        Api.create_message(msg.channel_id, "Need to be in a voice channel to run me.")

      {:existing, _session_process, _session_config} ->
        Api.create_message(msg.channel_id, "A session is already running in this server.")

      {:new_session, session_config} ->
        Bobochacha.Supervisor.start_session(session_config)
    end
  end

  defp handle_stop_session(msg) do
    case session_in_guild_of(msg) do
      :not_in_voice_channel ->
        Api.create_message(msg.channel_id, "No sessions found in this server.")

      {:new_session, _session_config} ->
        Api.create_message(msg.channel_id, "No sessions found in this server.")

      {:existing, session_process, _config} ->
        Bobochacha.SessionProcess.stop_session(session_process)
    end
  end

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    case msg.content do
      "pd!start" -> handle_start_session(msg)
      "pd!stop" -> handle_stop_session(msg)
      _ -> :noop
    end
  end

  # Default event handler, if you don't include this, your consumer WILL crash if
  # you don't have a method definition for each event type.
  def handle_event(_event) do
    :noop
  end
end

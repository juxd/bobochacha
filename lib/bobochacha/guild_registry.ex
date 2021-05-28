defmodule Bobochacha.GuildRegistry do
  def start_link do
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  def via_tuple(session_config) do
    {:via, Registry, {__MODULE__, session_config.guild_id, session_config}}
  end

  def child_spec(_) do
    Supervisor.child_spec(Registry, id: __MODULE__, start: {__MODULE__, :start_link, []})
  end

  def lookup(guild_id) do
    Registry.lookup(__MODULE__, guild_id)
  end
end

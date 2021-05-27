defmodule Bobochacha.GuildRegistry do
  def start_link do
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  def via_tuple(guild_id) do
    {:via, Registry, {__MODULE__, guild_id}}
  end

  def child_spec do
    Supervisor.child_spec(Registry, id: __MODULE__, start: {__MODULE__, :start_link, []})
  end
end

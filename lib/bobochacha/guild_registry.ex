defmodule Bobochacha.GuildRegistry do
  def start_link do
    Registry.start_link(keys: :unique, name: __MODULE__)
  end

  def via_tuple(guild_id, session_meta \\ %{}) do
    {:via, Registry, {__MODULE__, guild_id, session_meta}}
  end

  def child_spec(_) do
    Supervisor.child_spec(Registry, id: __MODULE__, start: {__MODULE__, :start_link, []})
  end
end

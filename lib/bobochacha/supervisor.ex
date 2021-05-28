defmodule Bobochacha.Supervisor do
  use DynamicSupervisor

  alias Bobochacha.GuildRegistry

  @impl DynamicSupervisor
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, _arg, name: __MODULE__)
  end

  def start_session(session_config, guild_id) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Bobochacha.SessionProcess, {session_config, guild_id}}
    )
  end
end

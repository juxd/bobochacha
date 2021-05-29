defmodule Bobochacha.Supervisor do
  use DynamicSupervisor

  @impl DynamicSupervisor
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_link(arg) do
    DynamicSupervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def start_session(session_config) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {Bobochacha.SessionProcess, session_config}
    )
  end
end

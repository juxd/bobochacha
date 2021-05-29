defmodule Bobochacha.Application do
  use Application

  @impl Application
  def start(_, _) do
    Supervisor.start_link(
      [
        Bobochacha.GuildRegistry,
        Bobochacha.Supervisor,
        Bobochacha.Consumer
      ],
      strategy: :one_for_one
    )
  end
end

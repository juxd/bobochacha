defmodule Bobochacha.Consumer do
  use Nostrum.Consumer

  alias Nostrum.Api
  alias Nostrum.Cache.GuildCache

  def start_link do
    Consumer.start_link(__MODULE__)
  end

  defp existing_session_in_guild_or_new(msg) do
    case Registry.lookup(Bobochacha.GuildRegistry, msg.guild_id) do
      [] -> {:new_session}
      [{_, session_meta}] -> {:existing, session_meta}
    end
  end
end

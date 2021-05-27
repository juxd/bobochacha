defmodule Bobochacha.SessionConfig do
  @enforce_keys [:text_channel, :voice_channel]

  defstruct [
    :text_channel,
    :voice_channel,
    cycles_to_run: 12,
    minutes_for_work: 25,
    minutes_for_small_break: 5,
    minutes_for_big_break: 15
  ]
end

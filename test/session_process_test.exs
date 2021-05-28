defmodule SessionProcessTest do
  alias Bobochacha.SessionProcess
  alias Bobochacha.SessionConfig
  use ExUnit.Case, async: true
  @dummy_user_id 69
  @dummy_guild_id 69_420

  setup do
    start_supervised!(Bobochacha.GuildRegistry)

    %{
      session_process:
        start_supervised!(
          {SessionProcess,
           %SessionConfig{
             creator: @dummy_user_id,
             guild_id: @dummy_guild_id,
             text_channel: nil,
             voice_channel: nil,
             cycles_to_run: 2
           }}
        )
    }
  end

  test "transitions are correct", %{session_process: session_process} do
    assert {:on_break, 0, _} = SessionProcess.state_for_testing(session_process)
    SessionProcess.tick_timer_for_testing(session_process)
    assert {:working, 1, _} = SessionProcess.state_for_testing(session_process)
    SessionProcess.tick_timer_for_testing(session_process)
    assert {:on_break, 1, _} = SessionProcess.state_for_testing(session_process)
    SessionProcess.tick_timer_for_testing(session_process)
    assert {:working, 2, _} = SessionProcess.state_for_testing(session_process)
    SessionProcess.tick_timer_for_testing(session_process)
    assert {:on_break, 2, _} = SessionProcess.state_for_testing(session_process)
    SessionProcess.tick_timer_for_testing(session_process)
    refute_receive {:DOWN, _}, 500
  end
end

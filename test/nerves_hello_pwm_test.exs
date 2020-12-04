defmodule NervesHelloPwmTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "schedule pwm" do
    run_one_second = fn ->
      assert {:ok, _pid} =
               NervesHelloPwm.PwmScheduler.start_link(%{
                 id: 19,
                 frequency: 2,
                 duty_cycle: 50,
                 on_fn: fn -> IO.puts("on") end,
                 off_fn: fn -> IO.puts("off") end
               })

      :timer.sleep(1000)
    end

    assert capture_io(run_one_second) ==
             """
             on
             off
             on
             off
             """

    assert {:error, {:already_started, _pid}} =
             NervesHelloPwm.PwmScheduler.start_link(%{
               id: 19,
               frequency: 2,
               duty_cycle: 50,
               on_fn: fn -> IO.puts("on") end,
               off_fn: fn -> IO.puts("off") end
             })
  end
end

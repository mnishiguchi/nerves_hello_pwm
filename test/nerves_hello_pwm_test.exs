defmodule NervesHelloPwmTest do
  use ExUnit.Case
  doctest NervesHelloPwm

  test "greets the world" do
    assert NervesHelloPwm.hello() == :world
  end
end

defmodule BobochachaTest do
  use ExUnit.Case
  doctest Bobochacha

  test "greets the world" do
    assert Bobochacha.hello() == :world
  end
end

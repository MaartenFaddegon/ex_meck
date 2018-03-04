defmodule ExMeckTest do
  use ExUnit.Case
  doctest ExMeck

  test "greets the world" do
    assert ExMeck.hello() == :world
  end
end

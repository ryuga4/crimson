defmodule Game.Player do
  @moduledoc false
  defstruct x: 0,
            y: 0,
            name: nil,
            hp: 100

  def move(%Game.Player{} = p, x,y) do
    %{p | x: p.x+x, y: p.y+y}
  end
end

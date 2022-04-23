defmodule IslandsEngine.Rules do
  alias IslandsEngine.Rules

  defstruct state: :initialized,
            player1: :islands_not_set,
            player2: :islands_not_set

  def new, do: %Rules{}

  def check(%Rules{state: :initialized} = rules, :add_player),
    do: {:ok, %Rules{rules | state: :players_set}}

  def check(%Rules{state: :players_set} = rules, {:position_islands, player}) do
    case Map.fetch!(rules, player) do
      :islands_set -> :error
      :islands_not_set -> {:ok, rules}
    end
  end

  def check(%Rules{state: :players_set} = rules, {:set_islands, player}) do
    rules = Map.put(rules, player, :islands_set)

    case both_players_islands_set?(rules) do
      true -> {:ok, %Rules{rules | state: :player1_turn}}
      false -> {:ok, rules}
    end
  end

  def check(%Rules{state: :player1_turn} = rules, {:guess_coordinate, :player1}) do
    {:ok, %Rules{rules | state: :player2_turn}}
  end

  def check(_state, _action), do: :error

  defp both_players_islands_set?(rules) do
    rules.player1 == :islands_set and rules.player2 == :islands_set
  end
end

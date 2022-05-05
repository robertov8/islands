defmodule IslandsEngine.Game do
  use GenServer

  alias IslandsEngine.{Board, Coordinate, Guesses, Island, Rules}

  @timeout 60 * 60 * 24 * 1000
  @players [:player1, :player2]

  ########
  # Client
  ########

  def start_link(name) when is_binary(name) do
    GenServer.start_link(__MODULE__, name, name: via_tuple(name))
  end

  def via_tuple(name), do: {:via, Registry, {Registry.Game, name}}

  def add_player(game, name) when is_binary(name) do
    GenServer.call(game, {:add_player, name})
  end

  def demo_call(game), do: GenServer.call(game, :demo_call)

  def demo_cast(game, new_value), do: GenServer.cast(game, {:demo_cast, new_value})

  def position_island(game, player, key, row, col) when player in @players do
    GenServer.call(game, {:position_island, player, key, row, col})
  end

  def set_islands(game, player) when player in @players do
    GenServer.call(game, {:set_islands, player})
  end

  def guess_coordinate(game, player, row, col) when player in @players do
    GenServer.call(game, {:guess_coordinate, player, row, col})
  end

  ############
  # Callbacks
  ############
  def init(name) do
    send(self(), {:set_state, name})
    {:ok, fresh_state(name)}
  end

  defp fresh_state(name) do
    player1 = %{name: name, board: Board.new(), guesses: Guesses.new()}
    player2 = %{name: nil, board: Board.new(), guesses: Guesses.new()}
    %{player1: player1, player2: player2, rules: Rules.new()}
  end

  def handle_call({:add_player, name}, _from, state) do
    with {:ok, rules} <- Rules.check(state.rules, :add_player) do
      state
      |> update_player2_name(name)
      |> update_rules(rules)
      |> replay_success(:ok)
    else
      :error -> {:replay, :error, state}
    end
  end

  def handle_call(:demo_call, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:position_island, player, key, row, col}, _from, state) do
    board = player_board(state, player)

    with {:ok, rules} <- Rules.check(state.rules, {:position_islands, player}),
         {:ok, coordinate} <- Coordinate.new(row, col),
         {:ok, island} <- Island.new(key, coordinate),
         %{} = board <- Board.position_island(board, key, island) do
      state
      |> update_board(player, board)
      |> update_rules(rules)
      |> replay_success(:ok)
    else
      :error ->
        {:reply, :error, state}

      {:error, :overlapping_island} ->
        {:reply, {:error, :overlapping_island}, state}

      {:error, :invalid_coordinate} ->
        {:reply, {:error, :invalid_coordinate}, state}

      {:error, :invalid_island_type} ->
        {:reply, {:error, :invalid_island_type}, state}
    end
  end

  def handle_call({:set_islands, player}, _from, state) do
    board = player_board(state, player)

    with {:ok, rules} <- Rules.check(state.rules, {:set_islands, player}),
         true <- Board.all_islands_positioned?(board) do
      state
      |> update_rules(rules)
      |> replay_success({:ok, board})
    else
      :error -> {:reply, :error, state}
      false -> {:reply, {:error, :not_all_islands_positioned}, state}
    end
  end

  def handle_call({:guess_coordinate, player, row, col}, _from, state) do
    opponent = opponent(player)
    opponent_board = player_board(state, opponent)

    with {:ok, rules} <- Rules.check(state.rules, {:guess_coordinate, player}),
         {:ok, coordinate} <- Coordinate.new(row, col),
         {hit_or_miss, forested_island, win_status, opponent_board} <-
           Board.guess(opponent_board, coordinate),
         {:ok, rules} <- Rules.check(rules, {:win_check, win_status}) do
      state
      |> update_board(opponent, opponent_board)
      |> update_guess(player, hit_or_miss, coordinate)
      |> update_rules(rules)
      |> replay_success({hit_or_miss, forested_island, win_status})
    else
      :error ->
        {:reply, :error, state}

      {:error, :invalid_coordinate} ->
        {:reply, {:error, :invalid_coordinate}, state}
    end
  end

  def handle_cast({:demo_cast, new_value}, state) do
    {:noreply, Map.put(state, :test, new_value)}
  end

  def handle_info(:first, state) do
    IO.puts("This message has been handled by handle_info/2, matching on :first.")

    {:noreply, state}
  end

  def handle_info(:timeout, state) do
    {:stop, {:shutdown, :timeout}, state}
  end

  def handle_info({:set_state, name}, _state) do
    state =
      case :ets.lookup(:game_state, name) do
        [] -> fresh_state(name)
        [{_key, state}] -> state
      end

    :ets.insert(:game_state, {name, state})
    {:noreply, state, @timeout}
  end

  def terminate({:shutdown, :timeout}, state) do
    :ets.delete(:game_state, state.player1.name)

    :ok
  end

  def terminate(_reason, _state), do: :ok

  defp update_player2_name(state, name), do: put_in(state.player2.name, name)

  defp update_rules(state, rules), do: %{state | rules: rules}

  defp update_guess(state, player_key, hit_or_miss, coordinate) do
    update_in(state[player_key].guesses, fn guesses ->
      Guesses.add(guesses, hit_or_miss, coordinate)
    end)
  end

  defp replay_success(state, replay) do
    :ets.insert(:game_state, {state.player1.name, state})
    {:reply, replay, state, @timeout}
  end

  defp player_board(state, player), do: Map.get(state, player).board

  defp update_board(state, player, board),
    do: Map.update!(state, player, fn player -> %{player | board: board} end)

  defp opponent(:player1), do: :player2

  defp opponent(:player2), do: :player1
end

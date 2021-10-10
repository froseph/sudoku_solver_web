defmodule Sudoku.Solver.CPS do
  @moduledoc """
  Implements  SolverProtocol using continuation passing style
  """
  alias Sudoku.Solver.Protocol, as: SolverProtocol
  alias Sudoku.Solver.Board, as: SolverBoard

  @behaviour SolverProtocol

  @doc """
  Solve a soduku
  """
  @impl SolverProtocol
  @spec solve(SolverBoard.t()) :: SolverBoard.t() | nil
  def solve(%SolverBoard{size: size} = board) do
    max_index = size * size - 1
    board = SolverBoard.eliminate_candidates(board)
    solve_helper(board, max_index, fn -> nil end)
  end

  # Solves sudoku by attempting to populate cells starting at the end of the board and moving
  # to the front. Solve helper keps track of which cell we are currently trying.
  # It calls the failure continuation `fc` when needs to backtrack.
  @spec solve_helper(SolverBoard.t(), integer(), fun()) ::
          SolverBoard.t() | any()
  defp solve_helper(%SolverBoard{} = board, -1, fc) do
    if SolverBoard.solved?(board), do: board, else: fc.()
  end

  defp solve_helper(%SolverBoard{} = board, idx, fc) do
    candidates = SolverBoard.get_candidates(board, idx)

    if Enum.count(candidates) == 1 do
      solve_helper(board, idx - 1, fc)
    else
      try_solve(board, idx, MapSet.to_list(candidates), fc)
    end
  end

  # try_solve attempts to solve a board by populating a cell from a list of suggestions
  defp try_solve(%SolverBoard{}, _idx, [], fc), do: fc.()

  defp try_solve(%SolverBoard{} = board, idx, [suggestion | other_suggestions], fc) do
    position = SolverBoard.index_to_position(board, idx)
    {:ok, new_board} = SolverBoard.place_number(board, position, suggestion)
    new_board = SolverBoard.eliminate_candidates(new_board)

    if SolverBoard.partial_solution?(new_board) do
      solve_helper(new_board, idx - 1, fn -> try_solve(board, idx, other_suggestions, fc) end)
    else
      try_solve(board, idx, other_suggestions, fc)
    end
  end

  @doc """
  Finds all possible solutions to a sudoku.

  ## Parameters

    - board: A sudoku board
  """
  @impl SolverProtocol
  @spec all_solutions(SolverBoard.t()) :: [SolverBoard.t()]
  def all_solutions(%SolverBoard{} = board) do
    max_index = board.size * board.size - 1
    board = SolverBoard.eliminate_candidates(board)
    find_all_solutions_helper(board, max_index, fn -> [] end)
  end

  defp find_all_solutions_helper(board, -1, continuation) do
    if SolverBoard.solved?(board) do
      [board | continuation.()]
    else
      continuation.()
    end
  end

  defp find_all_solutions_helper(board, idx, continuation) do
    candidates = SolverBoard.get_candidates(board, idx)

    if Enum.count(candidates) == 1 do
      find_all_solutions_helper(board, idx - 1, continuation)
    else
      try_find_all_solutions(board, idx, MapSet.to_list(candidates), continuation)
    end
  end

  defp try_find_all_solutions(_board, _idx, [], continuation), do: continuation.()

  defp try_find_all_solutions(board, idx, [suggestion | other_suggestions], continuation) do
    position = SolverBoard.index_to_position(board, idx)
    {:ok, new_board} = SolverBoard.place_number(board, position, suggestion)
    new_board = SolverBoard.eliminate_candidates(new_board)

    if SolverBoard.partial_solution?(new_board) do
      find_all_solutions_helper(new_board, idx - 1, fn ->
        try_find_all_solutions(board, idx, other_suggestions, continuation)
      end)
    else
      try_find_all_solutions(board, idx, other_suggestions, continuation)
    end
  end
end

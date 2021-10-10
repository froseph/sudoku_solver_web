defmodule Sudoku.Solver.Protocol do
  alias Sudoku.Solver.Board

  @moduledoc """
  Defines a sudoku solver behavior
  """

  @doc """
  Finds a solution to a Sudoku, returning nil if the board is impossible to solve.

  ## Parameters

    - board: A sudoku board
  """
  @callback solve(board :: Board.t()) :: Board.t() | nil

  @doc """
  Finds all possible solutions to a sudoku.

  ## Parameters

    - board: A sudoku board
  """
  @callback all_solutions(board :: Board.t()) :: [Board.t()]
end

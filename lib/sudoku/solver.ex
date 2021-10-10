defmodule Sudoku.Solver do
  def solve(%Sudoku.Board.Board{} = board) do
    solution =
      board
      |> Sudoku.Board.to_list()
      |> Sudoku.Solver.Board.new()
      |> Sudoku.Solver.CPS.solve()

    solution
    |> Sudoku.Solver.Board.to_list()
    |> Sudoku.Board.from_list()
  end

  # defp convert_board(%Sudoku.Board.Board{}) do
  #   nil
  # end
end

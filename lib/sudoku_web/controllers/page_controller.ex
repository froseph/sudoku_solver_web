defmodule SudokuWeb.PageController do
  use SudokuWeb, :controller

  def index(conn, _params) do
    # Generate Empty Board
    changeset =
      List.duplicate(0, 81)
      |> Sudoku.Board.from_list()
      |> Sudoku.Board.change_board()

    render(conn, "index.html", changeset: changeset)
  end

  def update(conn, %{"board" => board_params}) do
    changeset =
      Sudoku.Board.update_board(%Sudoku.Board.Board{}, board_params)
      |> Sudoku.Solver.solve()
      |> Sudoku.Board.change_board()

    render(conn, "index.html", changeset: changeset)
  end
end

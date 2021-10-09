defmodule SudokuWeb.PageController do
  use SudokuWeb, :controller
  alias Sudoku.Board.Board

  def index(conn, _params) do
    # Test board
    test_cells =
      for row <- 0..8 do
        for col <- 0..8 do
          %Sudoku.Board.Cell{row: row, col: col}
        end
      end
      |> List.flatten()

    changeset = Board.test_changeset(%Board{size: 9}, %{cells: test_cells})

    render(conn, "index.html", changeset: changeset)
  end

  def update(conn, %{"board" => board_params}) do
    changeset = Board.changeset(%Board{}, board_params)
    render(conn, "index.html", changeset: changeset)
  end
end

defmodule Sudoku.Board do
  alias Sudoku.Board.Board
  alias Sudoku.Board.Cell

  def change_board(%Board{} = board, attrs \\ %{}) do
    Board.changeset(board, attrs)
  end

  def update_board(%Board{} = board, attrs) do
    board
    |> Board.changeset(attrs)
    |> Ecto.Changeset.apply_action!(:update)
  end

  # TODO remove hardcoded size
  @board_size 9
  def from_list(list_rep) do
    cells =
      for {value, index} <- Enum.with_index(list_rep) do
        {row, col} = index_to_position(index, @board_size)
        value = if value == 0, do: nil, else: value
        %Cell{row: row, col: col, value: value}
      end

    %Board{size: @board_size, cells: cells}
  end

  defp index_to_position(index, size), do: {div(index, size), rem(index, size)}

  def to_list(%Board{cells: cells, size: size}) do
    sorted_cells =
      Enum.sort(
        cells,
        fn %Cell{row: row1, col: col1}, %Cell{row: row2, col: col2} ->
          row1 * size + col1 <= row2 * size + col2
        end
      )

    Enum.map(sorted_cells, fn
      %Cell{value: nil} -> 0
      %Cell{value: value} -> value
    end)
  end
end

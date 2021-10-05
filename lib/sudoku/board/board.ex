defmodule Sudoku.Board.Board do
  use Ecto.Schema

  import Ecto.Changeset
  alias Sudoku.Board.Cell

  # TODO: decouple the size
  @size 9

  embedded_schema do
    field(:size, :integer)
    embeds_many(:cells, Cell)
  end

  def changeset(board, attrs \\ %{}) do
    board
    |> cast(attrs, [:size])
    |> put_embed(:cells, Map.get(attrs, :cells))
    |> validate_change(:cells, &validate_cells/2)
  end

  defp validate_cells(:cells, cells) do
    set = MapSet.new(cells, fn c -> {c.data.row, c.data.col} end)

    cond do
      Enum.count(set) != Enum.count(cells) ->
        ["Board cannot contain duplicate cells"]

      Enum.any?(set, fn {row, col} ->
        not (0 <= row and row < @size and
               0 <= col and col < @size)
      end) ->
        ["Board contains a cell with index out of bounds"]

      # TODO does this need to be here? We should allow people to type in garbage
      Enum.any?(cells, fn c -> not (0 <= c.data.value and c.data.value <= @size) end) ->
        ["Board contains a value with value out of bounds"]

      true ->
        []
    end
  end
end

defmodule Sudoku.Board.Cell do
  use Ecto.Schema

  import Ecto.Changeset

  embedded_schema do
    field(:row, :integer)
    field(:col, :integer)
    field(:value, :integer)
  end

  def changeset(cell, attrs \\ %{}) do
    cell
    |> cast(attrs, [:row, :col, :value])
    |> validate_required([:row, :col])
    |> validate_number(:row, greater_than_or_equal_to: 0)
    |> validate_number(:col, greater_than_or_equal_to: 0)
    |> validate_number(:value, greater_than_or_equal_to: 0)
  end
end

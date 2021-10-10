defmodule Sudoku.Solver.Board do
  alias Sudoku.Solver.Board

  @moduledoc """
  Implements a Sudoku board
  """
  @enforce_keys [:size, :grid]
  defstruct [:size, :grid]

  @type index :: non_neg_integer()
  @type position :: {non_neg_integer(), non_neg_integer()}
  @type candidate :: non_neg_integer()
  @type candidates :: MapSet.t(non_neg_integer())
  @type cell :: {position, candidates}
  @type t :: %Board{
          size: integer,
          grid: %{Board.position() => Board.candidates()}
        }

  @spec equals?(Board.t(), Board.t()) :: boolean
  def equals?(board1, board2) do
    board1.size == board2.size and board1.grid == board2.grid
  end

  @spec to_list(Board.t()) :: list(non_neg_integer())
  def to_list(%Board{grid: grid, size: size}) do
    grid
    |> Map.to_list()
    |> Enum.sort(fn {{row1, col1}, _}, {{row2, col2}, _} ->
      row1 * size + col1 <= row2 * size + col2
    end)
    |> Enum.map(fn {_, value} ->
      if MapSet.size(value) == 1, do: Enum.fetch!(value, 0), else: 0
    end)
  end

  @spec index_to_position(t(), non_neg_integer()) :: position()
  def index_to_position(%Board{size: size}, idx) do
    index_to_position_internal(idx, size)
  end

  @spec get_candidates(t(), non_neg_integer()) :: candidates()
  def get_candidates(%Board{} = board, index) when is_integer(index) do
    get_candidates(board, index_to_position(board, index))
  end

  @spec get_candidates(t(), position()) :: candidates()
  def get_candidates(%Board{} = board, position) when tuple_size(position) == 2 do
    Map.get(board.grid, position)
  end

  defp index_to_position_internal(index, size), do: {div(index, size), rem(index, size)}
  defp position_to_index_internal(row, col, size), do: row * size + col

  @doc """
  Creates a sudokuboard from a list. No validation checking is done.

  ## Parameters

    - grid: A integer list representing a board. Element 0 is at top left, n is at bottom right.
  """
  @spec new(list(non_neg_integer())) :: Board.t()
  def new(grid) do
    size =
      grid
      |> Enum.count()
      |> integer_sqrt

    transformed_grid =
      for {value, index} <- Enum.with_index(grid), into: %{} do
        position = index_to_position_internal(index, size)
        candidates = if value != 0, do: MapSet.new([value]), else: MapSet.new(1..size)
        {position, candidates}
      end

    %Board{grid: transformed_grid, size: size}
  end

  @doc """
  Parses a string representation of a sudoku board.

  Each board is a CSV containing digits 0-n where `n` x `n` is the size of the board.
  Zeros represent empty spaces.

  ## Parameters

    - board_string: A string representing a board

  ## Examples

    iex> SudokuBoard.parse("0,0,1,2,0,0,0,0,1,2,3,4,0,0,0,0")
    {:ok,
     %SudokuBoard{grid: [0, 0, 1, 2, 0, 0, 0, 0, 1, 2, 3, 4, 0, 0, 0, 0], size: 4}}

    iex> SudokuBoard.parse("0,0,1")
    {:error, "Invalid board"}

  """
  @spec parse(String.t()) :: {:ok, Board.t()} | {:error, String.t()}
  def parse(str) do
    try do
      grid =
        str
        |> String.split(",")
        |> Enum.map(fn elt -> elt |> String.trim() |> Integer.parse() |> elem(0) end)

      board = Board.new(grid)

      {:ok, board}
    rescue
      _ -> {:error, "Parsing error"}
    end
  end

  # propogate constraintsc:w
  #
  @spec eliminate_candidates(Board.t()) :: Board.t()
  def eliminate_candidates(%Board{} = board) do
    filled_cells = Enum.filter(board.grid, fn {_, candidates} -> MapSet.size(candidates) == 1 end)

    new_board =
      Enum.reduce(filled_cells, board, fn {_position, value} = cell, acc ->
        get_affected_cells(acc, cell)
        |> eliminate_candidates_helper(value, acc)
      end)

    if equals?(board, new_board) do
      new_board
    else
      eliminate_candidates(new_board)
    end
  end

  defp eliminate_candidates_helper([], _value, acc), do: acc

  defp eliminate_candidates_helper([{position, _value} | other_cells], value, acc) do
    new_grid = Map.update!(acc.grid, position, fn x -> MapSet.difference(x, value) end)
    new_acc = %{acc | grid: new_grid}

    eliminate_candidates_helper(other_cells, value, new_acc)
  end

  defp get_affected_cells(%Board{} = board, cell) do
    row_index = get_row_index(cell)
    col_index = get_col_index(cell)

    box_size = integer_sqrt(board.size)
    box_index = get_box_index(cell, box_size)

    board.grid
    |> Enum.filter(fn x ->
      (get_row_index(x) == row_index or get_col_index(x) == col_index or
         get_box_index(x, box_size) == box_index) and x != cell
    end)
  end

  # assumes a valid sudoku board
  @doc """
  Validates if a board is a partial solution

  ## Parameters

    - board: A sudoku board
  """
  @spec partial_solution?(t()) :: boolean
  def partial_solution?(%Board{} = board) do
    board.grid
    |> Enum.all?(fn {_key, candidates} -> MapSet.size(candidates) >= 0 end)
  end

  @doc """
  Reads a sudoku board from a file

  ## Parameters

    - file_path: string representing the file path of the file to be loaded
  """
  @spec read_file(String.t()) :: {:ok, Board.t()} | {:error, String.t()}
  def read_file(path) do
    case File.read(path) do
      {:ok, data} -> parse(data)
      {:error, reason} -> {:error, "File error: " <> Atom.to_string(reason)}
    end
  end

  @doc """
  Place a number into the sudoku board. Does not ensure that the square is empty.

  ## Parameters

    - board: A sudoku board
    - index: An index into the board
    - number: The number to be placed into the board
  """
  @spec place_number(t(), position(), candidate()) :: {:ok, t()} | {:error, String.t()}
  def place_number(%Board{size: size, grid: grid} = board, position, candidate)
      when 1 <= candidate and candidate <= size do
    if MapSet.member?(grid[position], candidate) do
      new_grid = Map.replace(grid, position, MapSet.new([candidate]))
      {:ok, %{board | grid: new_grid}}
    else
      {:error, "Invalid move"}
    end

    # TODO propagate constraints?
    # TODO return error in sudoku_board 1
    # TODO validate placement is ok on sudoku_board 1
  end

  @doc """
  Tests if the board is solved

  ## Parameters

    - board: A Sudokuboard.t representing a board

  ## Examples


    iex> SudokuBoard.new([1,2,3,4,
    ...> 3,4,1,2,
    ...> 4,1,2,3,
    ...> 2,3,4,1]) |> SudokuBoard.solved?
    true

  """
  @spec solved?(Board.t()) :: boolean
  def solved?(%Board{} = board) do
    filled?(board) and partial_solution?(board)
  end

  @doc """
  Checks if a sudoku board is well formed.

  ## Parameters

    - board: A SudokuBoard.t representing a board
  """
  @spec valid?(Board.t()) :: boolean
  def valid?(%Board{size: size, grid: grid}) do
    valid_candidates = MapSet.new(1..size)

    square?(size) and
      Enum.count(grid) == size * size and
      grid
      |> Map.values()
      |> Enum.all?(fn candidates -> MapSet.subset?(candidates, valid_candidates) end)
  end

  ## Private methods

  # true if all squares in the board are populated
  defp filled?(%Board{grid: grid}) do
    Enum.all?(grid, fn {_, c} -> MapSet.size(c) == 1 end)
  end

  @spec square?(integer) :: boolean
  defp square?(i) do
    j = integer_sqrt(i)
    j * j == i
  end

  @spec integer_sqrt(integer) :: integer
  defp integer_sqrt(i), do: trunc(:math.sqrt(i))

  defp get_row_index({{_, y}, _} = _cell) do
    y
  end

  defp get_col_index({{x, _}, _} = _cell) do
    x
  end

  defp get_box_index(cell, box_size) do
    row = get_row_index(cell)
    col = get_col_index(cell)
    div(row, box_size) * box_size + div(col, box_size)
  end
end

defimpl String.Chars, for: Sudoku.Solver.Board do
  defp stringize_candidates(candidates, size) do
    for n <- 1..size, into: [] do
      if MapSet.member?(candidates, n), do: n, else: " "
    end
    |> Enum.join()
  end

  @spec to_string(Sudoku.Solver.Board.t()) :: String.t()
  def to_string(%Sudoku.Solver.Board{size: size, grid: grid}) do
    chunk_size =
      size
      |> :math.sqrt()
      |> trunc

    board_string =
      grid
      |> Enum.sort(fn {{x1, y1}, _}, {{x2, y2}, _} -> x1 + y1 * size < x2 + y2 * size end)
      |> Enum.map(fn {_, values} -> "|#{stringize_candidates(values, size)}" end)
      |> Enum.chunk_every(size)
      |> Enum.with_index()
      |> Enum.reduce("", fn {row, idx}, acc ->
        extra_rows =
          if rem(idx, chunk_size) == 0 do
            String.pad_trailing("\n\t    ", size * (size + 2) + 1, "*")
          else
            ""
          end

        "#{acc}#{extra_rows}\n\t    #{format_row(row, chunk_size)}"
      end)
      |> then(fn x -> x <> String.pad_trailing("\n\t    ", size * (size + 2) + 1, "*") end)
      |> String.trim()

    ~s/%Board{
      size: #{size},
      grid: #{board_string}
}/
  end

  defp format_row(row, chunk_size) do
    row
    |> Enum.chunk_every(chunk_size)
    |> Enum.reduce("", fn x, acc -> "#{acc}*#{x}" end)
    |> then(fn x -> x <> "*" end)
    |> String.trim()
  end
end

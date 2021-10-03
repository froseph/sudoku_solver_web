defmodule Sudoku.Repo do
  use Ecto.Repo,
    otp_app: :sudoku,
    adapter: Ecto.Adapters.Postgres
end

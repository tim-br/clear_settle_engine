defmodule ClearSettleEngine do
  use Application

  @moduledoc """
  Documentation for `ClearSettleEngine`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> ClearSettleEngine.hello()
      :world

  """
  def hello do
    :world
  end

  def start(_type, _args) do
    children = [
      ClearSettleEngine.Repo,
      {SuccessfulDayScheduler, []}
    ]

    opts = [strategy: :one_for_one, name: ClearSettleEngine.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

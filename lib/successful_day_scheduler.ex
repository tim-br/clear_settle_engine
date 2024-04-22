defmodule SuccessfulDayScheduler do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    IO.puts("initializing")

    spawn_task_and_wait()
    {:ok, nil}
  end

  def handle_info(:task_completed, state) do
    IO.puts("task completed")
    spawn_task_and_wait()
    {:noreply, state}
  end

  def spawn_task_and_wait do
    IO.puts("spawking task")
    pid = self()

    spawn_link(fn ->
      Mix.Tasks.SuccessfulDay.run([])
      send(pid, :task_completed)
    end)
  end
end

defmodule SuccessfulDayScheduler do
  use GenServer

  def start_link(_opts) do
    # false indicates that no task is currently running
    GenServer.start_link(__MODULE__, {:ok, false}, name: __MODULE__)
  end

  def init({:ok, task_running?}) do
    IO.puts("Initializing")
    # Initialize the state with the task_running flag
    {:ok, task_running?}
  end

  def handle_call(:start_transactions, _from, false) do
    IO.puts("Starting transactions")
    spawn_task_and_set_running()
    # Reply with :ok and update state to true
    {:reply, :ok, true}
  end

  def handle_call(:start_transactions, _from, true) do
    IO.puts("A task is already running. Ignoring request.")
    # Reply with an error tuple
    {:reply, {:error, :already_running}, true}
  end

  def handle_info(:task_completed, _state) do
    IO.puts("Task completed")
    # Set task_running to false to allow new tasks
    {:noreply, false}
  end

  defp spawn_task_and_set_running do
    IO.puts("Spawning task")
    pid = self()

    spawn_link(fn ->
      Mix.Tasks.SuccessfulDay.run([])
      send(pid, :task_completed)
    end)
  end
end

# defmodule SuccessfulDayScheduler do
#   use GenServer

#   def start_link(_opts) do
#     GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
#   end

#   def init(:ok) do
#     IO.puts("initializing")

#     spawn_task_and_wait()
#     {:ok, nil}
#   end

#   def handle_info(:task_completed, state) do
#     IO.puts("task completed")
#     spawn_task_and_wait()
#     {:noreply, state}
#   end

#   def spawn_task_and_wait do
#     IO.puts("spawking task")
#     pid = self()

#     spawn_link(fn ->
#       Mix.Tasks.SuccessfulDay.run([])
#       send(pid, :task_completed)
#     end)
#   end
# end

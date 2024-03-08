defmodule Mix.Tasks.Demo do
  use Mix.Task
  alias ClearSettleEngineSchemas.{Participant, Account, Security, SecurityBalance}
  alias ClearSettleEngine.{Repo}

  @shortdoc "Populates the database with sample data for demonstration."

  def run(_) do
    start_required_applications()
    {:ok, _} = Repo.start_link()

    # Create Participants
    1..2
    |> Enum.each(fn _ -> create_participant() end)

    # Create Securities
    1..3
    |> Enum.each(fn _ -> create_security() end)

    # Create Account Balances
    # ... (This depends on how you have structured your SecurityBalances schema)
  end

  def create_participant do
    participant_id = ("P-" <> :crypto.strong_rand_bytes(4)) |> Base.encode16()

    %Participant{participant_id: participant_id}
    |> Repo.insert!()
    |> create_accounts()
  end

  def create_accounts(participant) do
    Enum.each(1..2, fn _ ->
      account_number = ("A-" <> :crypto.strong_rand_bytes(4)) |> Base.encode16()

      %Account{account_number: account_number, participant_id: participant.id}
      |> Repo.insert!()
    end)
  end

  def create_security do
    security_id = ("S-" <> :crypto.strong_rand_bytes(4)) |> Base.encode16()

    %Security{security_id: security_id}
    |> Repo.insert!()
    |> create_balance()
  end

  def create_balance(security) do
    accounts = Repo.all(Account)

    Enum.each(accounts, fn account ->
      balance = Enum.random(200..5000)

      %SecurityBalance{account_id: account.id, security: security, balance: balance}
      |> Repo.insert!()
    end)
  end

  def start_required_applications do
    # List of applications that Repo depends on
    # Add other dependencies if necessary
    applications = [:logger, :ecto, :postgrex]

    # Start each application
    Enum.each(applications, fn app ->
      case Application.ensure_all_started(app) do
        {:ok, _started} ->
          :ok

        {:error, {app, reason}} ->
          raise "Failed to start application #{app}: #{inspect(reason)}"
      end
    end)
  end
end

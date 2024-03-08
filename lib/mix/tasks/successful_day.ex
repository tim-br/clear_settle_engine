defmodule Mix.Tasks.SuccessfulDay do
  use Mix.Task

  alias ClearSettleEngineSchemas.{Repo, Participant, Account, Security, SecurityBalance}
  alias ClearSettleEngine.{Repo}
  alias MarketEventProcessor
  alias ClearSettleEngine.Utils.MarketEventXmlConverter

  require Logger

  @length_of_day_in_seconds 10

  @shortdoc "Submits trades every 5 seconds."
  def run(_) do
    start_required_applications()
    {:ok, _} = Repo.start_link()
    Logger.configure(level: :info)

    Logger.info("Starting to submit trades...")
    accounts = Repo.all(Account)

    monitors = Enum.map(accounts, &spawn_monitor_account(&1))

    inf_loop(monitors)
  end

  def inf_loop(monitors) do
    receive do
      {:DOWN, ref, :process, _pid, _reason} ->
        remaining_monitors = Enum.reject(monitors, &(&1 == ref))

        if Enum.empty?(remaining_monitors) do
          IO.puts("All accounts processed. Exiting infinite loop.")
        else
          inf_loop(remaining_monitors)
        end
    after
      3000 ->
        inf_loop(monitors)
    end
  end

  def spawn_monitor_account(account) do
    pid = spawn_link(fn -> process_account(account) end)
    Process.monitor(pid)
  end

  def process_account(account) do
    start_time = :erlang.system_time(:seconds)
    loop_account_process(account, start_time)
  end

  def loop_account_process(account, start_time) do
    # Define how many times you want to process each account
    num_times_to_process = Enum.random(1..4)
    current_time = :erlang.system_time(:seconds)
    over = current_time - start_time > @length_of_day_in_seconds
    accounts = Repo.all(Account)
    securities = Repo.all(Security)

    Enum.each(1..num_times_to_process, fn _ ->
      sender = Enum.random(accounts)

      if(sender.id != account.id) do
        security = Enum.random(securities)

        # Fetch the balance of the sender
        sender_balance = fetch_account_balance(sender, security)

        quantity =
          cond do
            sender_balance < 1000 ->
              Enum.random(400..trunc(sender_balance * 1.2))

            sender_balance >= 1000 ->
              Enum.random(0..trunc(sender_balance * 1.1))
          end

        remainder = sender_balance - quantity

        if remainder > -250 and not over do
          trade = %{
            buy_side_account: account.account_number,
            sell_side_account: sender.account_number,
            security: security.security_id,
            quantity: quantity
            # Set other required fields for the Trade struct
          }

          MarketEventProcessor.process_market_event(trade, "trades")
        else
          if remainder > 0 do
            trade = %{
              buy_side_account: account.account_number,
              sell_side_account: sender.account_number,
              security: security.security_id,
              quantity: quantity
              # Set other required fields for the Trade struct
            }

            xml =
              trade
              |> MarketEventXmlConverter.to_xml("Trade")

            IO.puts("xml")
            IO.puts("#{inspect(xml)}")

            IO.puts("sending trade: #{inspect(trade)}")

            MarketEventProcessor.process_market_event(trade, "trades")
          end
        end
      end
    end)

    # Recursive call to loop again
    cond do
      over and not account_in_negative_balance?(account, securities) ->
        IO.puts("Exiting thread for account #{account.account_number} after 90 seconds")

      over ->
        random_duration_ms = :rand.uniform(1000) + 200
        Process.sleep(random_duration_ms)
        loop_account_process(account, start_time)

      true ->
        random_duration_ms = :rand.uniform(3000) + 2000
        Process.sleep(random_duration_ms)
        loop_account_process(account, start_time)
    end
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

  def fetch_account_balance(account, security) do
    balance_record =
      Repo.get_by(SecurityBalance,
        account_id: account.id,
        security_id: security.id
      )

    balance_record.balance
  end

  def account_in_negative_balance?(account, securities) do
    Enum.any?(securities, fn security ->
      balance = fetch_account_balance(account, security)
      balance < 0
    end)
  end
end

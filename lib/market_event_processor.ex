defmodule MarketEventProcessor do
  @moduledoc """
  Module responsible for processing market events.
  """

  alias ClearSettleEngine.Utils.MarketEventXmlParser
  alias ClearSettleEngine.{Repo}
  alias ClearSettleEngineSchemas.{Trade, Account, Security, SecurityBalance}

  import Ecto.Query
  require Logger

  @doc """
  Processes a market event by writing it to the database and updating relevant states.
  """
  def process_event(market_event, topic) do
    MarketEventXmlParser.parse_event(market_event, topic)
    |> process_market_event(topic)

    # case market_event do
    #   # %Trade{} = trade ->
    #   #   process_trade(trade)

    #   # %CorporateAction{} = ca ->
    #   #   process_corporate_action(ca)

    #   _ ->
    #     {:error, :invalid_event}
    # end
  end

  def process_market_event(trade, "trades") do
    # Implement the logic to process a trade event
    # - Write to database
    # - Update participant balances
    # - Perform other business logic
    # Database.write_trade(trade)
    # update_balances_and_state(trade)
    # ...

    ## IO.puts("receiving trade: #{inspect(trade)}")

    trade_data =
      trade
      |> Map.update(:buy_side_account, 0, fn account_number ->
        Repo.get_by(Account, account_number: account_number)
      end)
      |> Map.update(:sell_side_account, 0, fn account_number ->
        Repo.get_by(Account, account_number: account_number)
      end)
      |> Map.update(:security, 0, fn security_id ->
        Repo.get_by(Security, security_id: security_id)
      end)

    # IO.puts("trade data")
    # IO.puts("#{inspect(trade_data)}")

    trade_struct = struct(Trade, trade_data)

    # IO.puts("trade struct")
    # IO.puts("#{inspect(trade_struct)}")

    # Creating the trade
    case Repo.insert(trade_struct) do
      {:ok, trade} ->
        IO.puts("Trade created successfully: #{trade.id}")
        update_balances(trade)

      {:error, changeset} ->
        IO.puts("Failed to create trade: #{inspect(changeset)}")
    end

    {:ok, :processed_trade}
  end

  def process_market_event(event, "corporate_actions") do
    # Implement the logic to process a corporate action event
    # - Write to database
    # - Update participant balances
    # - Perform other business logic
    ### atabase.write_corporate_action(ca)
    ## update_balances_and_state(ca)
    IO.puts("corporate action is")
    IO.inspect(event)
    {:ok, :processed_corporate_action}
  end

  def update_balances(
        %Trade{
          security: security,
          sell_side_account: sell_side_account,
          buy_side_account: buy_side_account,
          quantity: quantity
        } = trade
      ) do
    IO.puts("updating balances")

    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:lock_seller, fn _repo, _changes ->
        lock_account_balance(sell_side_account.id, security.id)
      end)
      |> Ecto.Multi.run(:update_seller, fn _repo, _changes ->
        update_account_balance(sell_side_account.id, security.id, -quantity)
      end)
      |> Ecto.Multi.run(:lock_buyer, fn _repo, _changes ->
        lock_account_balance(buy_side_account.id, security.id)
      end)
      |> Ecto.Multi.run(:update_buyer, fn _repo, _changes ->
        update_account_balance(buy_side_account.id, security.id, quantity)
      end)

    try do
      case Repo.transaction(multi) do
        {:ok, _result} ->
          Logger.info("Transaction successful")

        {:error, reason} ->
          Logger.emergency("Transaction failed: #{inspect(reason)}")
          # Handle failure, log error, etc.
      end
    rescue
      e in Postgrex.Error ->
        if e.postgres.code == "40P01" do
          Logger.emergency("Deadlock detected during transaction")
          # Handle deadlock situation, e.g., retry the transaction
        else
          Logger.emergency("Database error: #{inspect(e)}")
          # Handle other database errors
        end
    end
  end

  def handle_deadlock(trade) do
    IO.puts("Deadlock detected for trade #{trade.id} on trade: #{inspect(trade)}")
    # A simple retry after a short delay
    # Random sleep between 0 and 1000 ms
    :timer.sleep(:rand.uniform(1000))
    process_market_event(trade, "trades")
  end

  def lock_account_balance(account_id, security_id) do
    query =
      from(sb in SecurityBalance,
        where: sb.account_id == ^account_id and sb.security_id == ^security_id,
        lock: "FOR UPDATE"
      )

    case Repo.one(query) do
      nil ->
        {:error, :not_found}

      balance ->
        {:ok, balance}
    end
  end

  def update_account_balance(account_id, security_id, quantity_change) do
    balance =
      Repo.get_by(SecurityBalance,
        account_id: account_id,
        security_id: security_id
      )

    case balance do
      nil ->
        # Create a new SecurityBalance record if it doesn't exist
        changeset =
          SecurityBalance.changeset(%SecurityBalance{}, %{
            account_id: account_id,
            security_id: security_id,
            balance: 0 + quantity_change
          })

        case Repo.insert(changeset) do
          {:ok, new_balance} -> {:ok, new_balance}
          {:error, changeset} -> {:error, changeset}
        end

      # Update the existing SecurityBalance record

      balance ->
        # If a record exists, update it
        changeset =
          SecurityBalance.changeset(balance, %{
            balance: balance.balance + quantity_change
          })

        case Repo.update(changeset) do
          {:ok, updated_balance} -> {:ok, updated_balance}
          {:error, changeset} -> {:error, changeset}
        end

        ## Repo.update!(updated_balance)
    end
  end

  # def process_corporate_action(ca) do
  #   # Implement the logic to process a corporate action event
  #   # - Write to database
  #   # - Update participant balances
  #   # - Perform other business logic
  #   Database.write_corporate_action(ca)
  #   update_balances_and_state(ca)
  #   # ...
  #   {:ok, :processed_corporate_action}
  # end

  # defp update_balances_and_state(event) do
  #   # Implement the logic for updating balances and state
  #   # ...
  #   {:ok, :updated}
  # end
end

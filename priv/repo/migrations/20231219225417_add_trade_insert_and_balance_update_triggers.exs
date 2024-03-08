defmodule ClearSettleEngine.Repo.Migrations.AddTradeInsertAndBalanceUpdateTriggers do
  use Ecto.Migration

  def up do
    # Function for new trade notification
    execute("""
    CREATE OR REPLACE FUNCTION notify_new_trade()
    RETURNS TRIGGER AS $$
    BEGIN
      PERFORM pg_notify('new_trade', json_build_object(
        'buy_side_account_id', NEW.buy_side_account_id,
        'sell_side_account_id', NEW.sell_side_account_id,
        'security_id', NEW.security_id,
        'quantity', NEW.quantity,
        'inserted_at', NEW.inserted_at
      )::text);
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    """)

    # Trigger for new trades
    execute("""
    CREATE TRIGGER trade_after_insert
    AFTER INSERT ON trades
    FOR EACH ROW EXECUTE FUNCTION notify_new_trade();
    """)

    # Function for security balance update notification
    execute("""
    CREATE OR REPLACE FUNCTION notify_security_balance_update()
    RETURNS TRIGGER AS $$
    BEGIN
      IF OLD.balance IS DISTINCT FROM NEW.balance THEN
        PERFORM pg_notify('security_balance_update', json_build_object(
          'account_id', NEW.account_id,
          'security_id', NEW.security_id,
          'balance', NEW.balance
        )::text);
      END IF;
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql;
    """)

    # Trigger for security balance updates
    execute("""
    CREATE TRIGGER security_balance_after_update
    AFTER UPDATE ON security_balances
    FOR EACH ROW EXECUTE FUNCTION notify_security_balance_update();
    """)
  end

  def down do
    # Drop the trigger for new trades
    execute("DROP TRIGGER IF EXISTS trade_after_insert ON trades;")
    # Drop the function for new trade notification
    execute("DROP FUNCTION IF EXISTS notify_new_trade;")

    # Drop the trigger for security balance updates
    execute("DROP TRIGGER IF EXISTS security_balance_after_update ON security_balances;")
    # Drop the function for security balance update notification
    execute("DROP FUNCTION IF EXISTS notify_security_balance_update;")
  end
end

defmodule ClearSettleEngine.Utils.TradeUtils do
  def create_trade_data(
        trade_id,
        trade_timestamp,
        security_id,
        security_type,
        quantity,
        price,
        buy_side_participant_id,
        buy_side_account_id,
        sell_side_participant_id,
        sell_side_account_id,
        settlement_date
      ) do
    %{
      "TradeId" => trade_id,
      "TradeTimestamp" => trade_timestamp,
      "SecurityId" => security_id,
      "SecurityType" => security_type,
      "Quantity" => quantity,
      "Price" => price,
      "BuySide" => %{
        "ParticipantId" => buy_side_participant_id,
        "AccountId" => buy_side_account_id
      },
      "SellSide" => %{
        "ParticipantId" => sell_side_participant_id,
        "AccountId" => sell_side_account_id
      },
      "SettlementDate" => settlement_date
    }
  end
end

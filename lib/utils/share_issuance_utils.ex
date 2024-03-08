defmodule ClearSettleEngine.Utils.ShareIssuanceUtils do
  def create_share_issuance_data(
        issuer,
        transfer_agent,
        security_id,
        security_type,
        issuance_date,
        share_price,
        recipients
      ) do
    %{
      "Issuer" => issuer,
      "TransferAgent" => transfer_agent,
      "SecurityId" => security_id,
      "SecurityType" => security_type,
      "IssuanceDate" => issuance_date,
      "SharePrice" => share_price,
      "Recipients" => recipients
    }
  end
end

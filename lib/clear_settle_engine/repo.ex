defmodule ClearSettleEngine.Repo do
  use Ecto.Repo,
    otp_app: :clear_settle_engine,
    adapter: Ecto.Adapters.Postgres
end

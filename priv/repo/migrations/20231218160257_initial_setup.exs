defmodule ClearSettleEngine.Repo.Migrations.InitialSetup do
  use Ecto.Migration

  def change do
    # Create participants table

    create table(:securities) do
      add(:security_id, :string)
      timestamps()
    end

    create table(:participants) do
      add(:participant_id, :string)
      timestamps()
    end

    # Create accounts table
    create table(:accounts) do
      add(:account_number, :string)
      add(:participant_id, references(:participants, on_delete: :nothing))
      timestamps()
    end

    # Create trades table
    create table(:trades) do
      add(:buy_side_account_id, references(:accounts, on_delete: :nothing))
      add(:sell_side_account_id, references(:accounts, on_delete: :nothing))
      add(:security_id, references(:securities, on_delete: :nothing))
      add(:status, :string)
      add(:rejection_reason, :string)
      add(:processing_time, :utc_datetime)
      add(:price, :decimal)
      add(:quantity, :integer)
      timestamps()
    end

    # Create accounts table
    create table(:security_balances) do
      add(:account_id, references(:accounts, on_delete: :nothing))
      add(:security_id, references(:securities, on_delete: :nothing))
      add(:balance, :integer)
      timestamps()
    end

    create(index(:securities, [:security_id]))
    create(index(:participants, [:participant_id]))
    create(index(:accounts, [:account_number]))
    create(unique_index(:security_balances, [:account_id, :security_id]))
  end
end

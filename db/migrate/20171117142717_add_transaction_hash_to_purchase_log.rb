class AddTransactionHashToPurchaseLog < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      add_column :purchase_logs, :transaction_hash, :string, limit: 255, null: true, after: :id
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      remove_column :purchase_logs, :transaction_hash
    end
  end

end

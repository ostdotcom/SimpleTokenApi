class AddStatusInContractEvent < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      add_column :contract_events, :status, :tinyint, limit: 4, null: false, after: :data
      add_column :contract_events, :block_number, :integer, null: false, after: :data

      change_column :contract_events, :kind, :tinyint, limit: 4, null: false

      add_index :contract_events, [:transaction_hash], unique: false, name: 'transaction_hash_index'
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      remove_column :contract_events, :status
      remove_column :contract_events, :block_number
      change_column :contract_events, :kind, :string, limit: 100, null: false
      remove_index :contract_events, name: 'transaction_hash_index'
    end
  end
end

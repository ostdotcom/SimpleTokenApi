class AddStatusInContractEvent < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      add_column :contract_events, :status, :tinyint, limit: 4, null: false, after: :data
      change_column :contract_events, :kind, :tinyint, limit: 4, null: false
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      remove_column :contract_events, :status
      change_column :contract_events, :kind, :string, limit: 100, null: false
    end
  end
end

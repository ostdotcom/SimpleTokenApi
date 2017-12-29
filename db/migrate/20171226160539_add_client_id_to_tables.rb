class AddClientIdToTables < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      add_column :user_kyc_details, :client_id, :integer, null: true, after: :id
      add_column :users, :client_id, :integer, null: true, after: :id
    end

    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      add_column :kyc_whitelist_logs, :client_id, :integer, null: true, after: :id
    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      remove_column :user_kyc_details, :client_id
      remove_column :users, :client_id
    end

    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      remove_column :kyc_whitelist_logs, :client_id
    end

  end

end
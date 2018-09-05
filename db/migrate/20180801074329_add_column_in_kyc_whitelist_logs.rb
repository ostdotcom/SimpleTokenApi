class AddColumnInKycWhitelistLogs < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      add_column :kyc_whitelist_logs, :client_whitelist_detail_id, :integer, :null => true, :after => :ethereum_address
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      remove_column :kyc_whitelist_logs, :client_whitelist_detail_id
    end
  end
end

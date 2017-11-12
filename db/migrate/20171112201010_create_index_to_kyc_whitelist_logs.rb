class CreateIndexToKycWhitelistLogs < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      add_index :kyc_whitelist_logs, :ethereum_address, unique: false, name: 'ethereum_address_index'
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      remove_index :kyc_whitelist_logs, 'ethereum_address_index'
    end
  end
end

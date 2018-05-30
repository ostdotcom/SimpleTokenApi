class AddNonceGasPriceTimestampInKycWhitelistLogs < DbMigrationConnection
  def self.up
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      add_column :kyc_whitelist_logs, :next_timestamp, :integer, null: true, default: 0, after: :transaction_hash
      add_column :kyc_whitelist_logs, :gas_price, :string, null: true, limit: 50, after: :transaction_hash
      add_column :kyc_whitelist_logs, :nonce, :string, null: true, limit: 50, after: :transaction_hash
    end
  end

  def self.down
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      remove_column :kyc_whitelist_logs, :nonce
      remove_column :kyc_whitelist_logs, :gas_price
      remove_column :kyc_whitelist_logs, :next_timestamp
    end
  end
end
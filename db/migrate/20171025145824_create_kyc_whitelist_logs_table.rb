class CreateKycWhitelistLogsTable < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      create_table :kyc_whitelist_logs do |t|
        t.column :ethereum_address, :string, limit: 255, null: false
        t.column :phase, :tinyint, limit: 1, null: false
        t.column :transaction_hash, :string, limit: 127, null: false
        t.column :status, :tinyint, limit: 1, null: false
        t.column :is_attention_needed, :tinyint, limit: 1, null: false, default: 0
        t.timestamps
      end

      add_index :kyc_whitelist_logs, [:transaction_hash], unique: true, name: 'uni_transaction_hash'
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      drop_table :kyc_whitelist_logs
    end
  end

end

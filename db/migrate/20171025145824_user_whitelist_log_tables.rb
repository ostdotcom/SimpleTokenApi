class UserWhitelistLogTables < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      create_table :user_kyc_whitelist_logs do |t|
        t.column :user_id, :integer, limit: 8, null: false
        t.column :transaction_hash, :string, limit: 255, null: false
        t.column :status, :tinyint, limit: 1, null: false
        t.column :attention_needed, :tinyint, limit: 1, null: false
        t.column :event_response_count, :tinyint, limit: 2, null: false, default: 0
        t.timestamps
      end

      add_index :user_kyc_whitelist_logs, [:transaction_hash], unique: true, name: 'uni_transaction_hash'
      # add_index :user_kyc_whitelist_logs, [:user_id], unique: true, name: 'uni_user_id'

    end
  end


  def down
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      drop_table :user_kyc_whitelist_logs
    end
  end

end

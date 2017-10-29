class UserContractEventTables < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      create_table :user_contract_events do |t|
        t.column :user_id, :integer, limit: 8
        t.column :kind, :string, limit: 100, null: false
        t.column :block_hash, :string, limit: 255, null: false
        t.column :transaction_hash, :string, limit: 255, null: false
        t.timestamps
      end
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      drop_table :user_contract_events
    end
  end

end

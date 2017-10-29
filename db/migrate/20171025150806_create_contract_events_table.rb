class CreateContractEventsTable < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      create_table :contract_events do |t|
        t.column :kind, :string, limit: 100, null: false
        t.column :transaction_hash, :string, limit: 255, null: false
        t.column :block_hash, :string, limit: 255, null: false
        t.column :data, :text, limit: 255, null: false
        t.timestamps
      end
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      drop_table :contract_events
    end
  end

end

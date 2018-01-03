class CreateClientWhitelistDetails < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      create_table :client_whitelist_details do |t|
        t.column :client_id, :integer, limit: 8, null: false
        t.column :contract_address, :string, null: false
        t.column :status, :tinyint, limit: 1, null: false
        t.timestamps
      end
      add_index :client_whitelist_details, :client_id, unique: true, name: 'uniq_client_id'
      add_index :client_whitelist_details, :contract_address, unique: true, name: 'uniq_contract_address'
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      drop_table :client_whitelist_details
    end
  end

end

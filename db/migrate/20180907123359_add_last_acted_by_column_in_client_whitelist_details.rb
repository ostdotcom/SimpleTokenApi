class AddLastActedByColumnInClientWhitelistDetails < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      add_column :client_whitelist_details, :last_acted_by, :integer, :null => true, :after => :suspension_type
      remove_index :client_whitelist_details, name: 'uniq_client_id'
      remove_index :client_whitelist_details, name: 'uniq_contract_address'
      remove_index :client_whitelist_details, name: 'uniq_whitelister_address'
      add_index :client_whitelist_details, [:client_id, :status], unique: false, name: 'uniq_client_id_status'
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      remove_index :client_whitelist_details, name: 'uniq_client_id_status'
      add_index :client_whitelist_details, :whitelister_address, unique: true, name: 'uniq_whitelister_address'
      add_index :client_whitelist_details, :contract_address, unique: true, name: 'uniq_contract_address'
      add_index :client_whitelist_details, [:client_id], unique: true, name: 'uniq_client_id'
      remove_column :client_whitelist_details, :last_acted_by
    end
  end
end
class AddColumnWhitelisterAddressToClientWhitelistDetailTable < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      add_column :client_whitelist_details, :whitelister_address, :string, limit: 255, null: true, after: :contract_address

      ClientWhitelistDetail.update_all('whitelister_address= id')
      change_column :client_whitelist_details, :whitelister_address, :string, limit: 255, null: false
      add_index :client_whitelist_details, :whitelister_address, unique: true, name: 'uniq_whitelister_address'
    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      remove_column :client_whitelist_details, :whitelister_address
      remove_index :client_whitelist_details, name: 'uniq_whitelister_address'
    end
  end

end

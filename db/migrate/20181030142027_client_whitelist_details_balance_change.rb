class ClientWhitelistDetailsBalanceChange < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      change_column :client_whitelist_details, :balance, :decimal, precision: 11, scale: 5, after: :whitelister_address, :null => true
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      change_column :client_whitelist_details, :balance, :decimal, precision: 8, scale: 2, after: :whitelister_address, :null => true
    end
  end
end



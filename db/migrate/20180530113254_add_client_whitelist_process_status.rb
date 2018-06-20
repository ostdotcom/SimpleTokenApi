class AddClientWhitelistProcessStatus < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      add_column :client_whitelist_details, :suspension_type, :tinyint, default: 0, after: :whitelister_address
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      remove_column :client_whitelist_details, :suspension_type
    end
  end

end

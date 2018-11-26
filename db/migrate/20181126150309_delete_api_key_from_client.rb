class DeleteApiKeyFromClient < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      remove_index :clients, name: 'uniq_api_key'
      remove_column :clients, :api_key
      remove_column :clients, :api_secret
    end
  end

  def down
  end

end

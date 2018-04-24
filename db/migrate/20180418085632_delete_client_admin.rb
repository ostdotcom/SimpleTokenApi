class DeleteClientAdmin < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      drop_table :client_admins
    end
  end

  def down
  end

end
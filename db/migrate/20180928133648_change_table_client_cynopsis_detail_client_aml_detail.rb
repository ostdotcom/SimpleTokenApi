class ChangeTableClientCynopsisDetailClientAmlDetail < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      rename_table :client_cynopsis_details, :client_aml_details
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      rename_table :client_aml_details, :client_cynopsis_details
    end
  end
end

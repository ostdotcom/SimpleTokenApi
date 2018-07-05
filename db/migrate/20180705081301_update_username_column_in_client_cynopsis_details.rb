class UpdateUsernameColumnInClientCynopsisDetails < DbMigrationConnection
  def self.up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      rename_column :client_cynopsis_details, :username, :email_id
    end
  end

  def self.down
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      rename_column :client_cynopsis_details, :email_id, :username
    end
  end
end

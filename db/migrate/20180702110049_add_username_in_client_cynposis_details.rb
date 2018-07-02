class AddUsernameInClientCynposisDetails < DbMigrationConnection
  def self.up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      add_column :client_cynopsis_details, :username, :string, limit: 50, null: true,  after: :client_id
    end
  end

  def self.down
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      remove_column :client_cynopsis_details, :username
    end
  end
end

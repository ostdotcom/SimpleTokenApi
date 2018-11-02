class AddRedirectUrlInClientWebHostDetail < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      add_column :client_web_host_details, :redirect_url, :string, limit: 250, after: :status, :null => true
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      remove_column :client_web_host_details, :redirect_url
    end
  end
end

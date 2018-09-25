class AddRegistrationEndTimestampInClientTokenSaleDetails < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      add_column :client_token_sale_details, :registration_end_timestamp, :integer, limit: 8, null: true, after: :sale_start_timestamp
    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      remove_column :client_token_sale_details, :registration_end_timestamp
    end
  end
end

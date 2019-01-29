class AddExtraKycFieldsColumn < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      add_column :client_kyc_config_details, :extra_kyc_fields, :text, after: :kyc_fields, null: true
    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      remove_column :client_kyc_config_details, :extra_kyc_fields
    end
  end

end

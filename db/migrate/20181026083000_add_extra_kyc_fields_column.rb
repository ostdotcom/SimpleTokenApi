class AddExtraKycFieldsColumn < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      add_column :client_kyc_config_details, :extra_kyc_fields, :text, after: :kyc_fields, null: true
    end

    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      add_column :user_extended_details, :extra_kyc_fields, :blob, after: :investor_proof_files_path, null: true
    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      remove_column :client_kyc_config_details, :extra_kyc_fields
    end

    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      remove_column :user_extended_details, :extra_kyc_fields
    end
  end

end

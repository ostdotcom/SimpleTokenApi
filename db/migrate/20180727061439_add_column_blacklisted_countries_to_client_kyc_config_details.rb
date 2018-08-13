class AddColumnBlacklistedCountriesToClientKycConfigDetails < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      add_column :client_kyc_config_details, :blacklisted_countries, :text, after: :residency_proof_nationalities, null: true
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      remove_column :client_kyc_config_details, :blacklisted_countries
    end
  end
end

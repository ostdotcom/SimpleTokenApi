class AddCaseIdStatusIndexInEditKycRequest < DbMigrationConnection
  def self.up
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      add_index :edit_kyc_requests, [:case_id, :status], unique: false, name: 'case_id_status'
    end
  end

  def self.down
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      remove_index :edit_kyc_requests, name: :case_id_status
    end
  end

end

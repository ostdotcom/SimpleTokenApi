class AddClientIdStatusIndexInUserKycDetail < DbMigrationConnection
  def self.up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      add_index :user_kyc_details, [:client_id, :status], unique: false, name: 'client_id_status'
    end
  end

  def self.down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      remove_index :user_kyc_details, name: :client_id_status
    end
  end
end

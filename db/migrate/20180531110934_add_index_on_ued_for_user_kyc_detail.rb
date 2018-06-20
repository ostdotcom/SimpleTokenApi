class AddIndexOnUedForUserKycDetail < DbMigrationConnection
  def self.up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      remove_index :user_kyc_details, name: :client_id_status
      add_index :user_kyc_details, [:client_id, :status, :user_extended_detail_id], unique: true, name: 'client_id_status_user_extended_detail_id'
    end
  end

  def self.down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      remove_index :user_kyc_details, name: :client_id_status_user_extended_detail_id
      add_index :user_kyc_details, [:client_id, :status], unique: false, name: 'client_id_status'
    end
  end
end

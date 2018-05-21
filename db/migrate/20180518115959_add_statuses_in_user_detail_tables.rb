class AddStatusesInUserDetailTables < DbMigrationConnection
  def self.up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      add_column :user_kyc_details, :status, :tinyint, limit: 1, null: false, default: 1, after: :whitelist_status
      change_column :users, :email, :string, null: true
      change_column :user_kyc_details, :kyc_confirmed_at, :integer, null: true
    end
  end

  def self.down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      remove_column :user_kyc_details, :status
      change_column :users, :email, :string, null: false
      change_column :user_kyc_details, :kyc_confirmed_at, :integer, null: false
    end
  end
end

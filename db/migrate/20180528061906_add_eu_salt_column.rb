class AddEuSaltColumn < DbMigrationConnection
  def self.up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      add_column :user_extended_details, :eu_kyc_salt, :blob, null: true, after: :kyc_salt
      add_column :user_secrets, :eu_login_salt, :blob, null: true, after: :login_salt
    end

    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      add_column :clients, :eu_api_salt, :blob, null: true, after: :api_salt
    end

    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do
      add_column :admin_secrets, :eu_login_salt, :blob, null: true, after: :login_salt
    end

    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      add_column :general_salts, :eu_salt, :blob, null: true, after: :salt
    end

  end

  def self.down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      remove_column :user_kyc_details, :eu_kyc_salt
      remove_column :user_secrets, :eu_login_salt
    end

    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      remove_column :clients, :eu_api_salt
    end

    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do
      remove_column :admin_secrets, :eu_login_salt
    end

    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      remove_column :general_salts, :eu_salt
    end

  end

end
class RenameEuSaltColumn < DbMigrationConnection
  def self.up
    # run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
    #   rename_column :user_extended_details, :kyc_salt, :us_kyc_salt
    #   rename_column :user_extended_details, :eu_kyc_salt, :kyc_salt
    #   rename_column :user_secrets, :login_salt, :us_login_salt
    #   rename_column :user_secrets, :eu_login_salt, :login_salt
    # end
    #
    # run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
    #   rename_column :clients, :api_salt, :us_api_salt
    #   rename_column :clients, :eu_api_salt, :api_salt
    # end
    #
    # run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do
    #   rename_column :admin_secrets, :login_salt, :us_login_salt
    #   rename_column :admin_secrets, :eu_login_salt, :login_salt
    # end
    #
    # run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
    #   rename_column :general_salts, :salt, :us_salt
    #   rename_column :general_salts, :eu_salt, :salt
    # end

  end

  def self.down

  end

end
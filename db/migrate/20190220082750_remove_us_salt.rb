class RemoveUsSalt < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      remove_column :user_secrets, :us_login_salt
      remove_column :user_extended_details, :us_kyc_salt
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do

    end
  end
end

class ModifyUserAutoIncrement < DbMigrationConnection
  def up

    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      execute ("ALTER TABLE users AUTO_INCREMENT = 11000")
      rename_column :user_kyc_details, :duplicate_status, :kyc_duplicate_status
      add_column :user_kyc_details, :email_duplicate_status, :tinyint, limit: 1, null: false, default: 0, after: :kyc_duplicate_status
    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      rename_column :user_kyc_details, :kyc_duplicate_status, :duplicate_status
      remove_column :user_kyc_details, :email_duplicate_status
    end

  end
end

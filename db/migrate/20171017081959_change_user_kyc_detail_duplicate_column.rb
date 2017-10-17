class ChangeUserKycDetailDuplicateColumn < DbMigrationConnection

  def up

    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      rename_column :user_kyc_details, :is_duplicate, :duplicate_status
    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      rename_column :user_kyc_details, :duplicate_status, :is_duplicate
    end
  end

end

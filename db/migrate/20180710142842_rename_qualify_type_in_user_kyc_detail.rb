class RenameQualifyTypeInUserKycDetail < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      rename_column :user_kyc_details, :qualify_type, :qualify_types
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      rename_column :user_kyc_details, :qualify_types, :qualify_type
    end
  end

end

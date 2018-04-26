class RenameColumnInUserKycDetail < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      rename_column :user_kyc_details, :admin_action_type, :admin_action_types
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      rename_column :user_kyc_details, :admin_action_types, :admin_action_type
    end
  end

end
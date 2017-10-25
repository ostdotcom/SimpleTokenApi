class AddUserKycDetailWhitelistColumn < DbMigrationConnection
  def up

    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      add_column :user_kyc_details, :whitelist_status, :tinyint, limit: 1, null: false, after: :admin_status
      add_column :user_kyc_details, :admin_action_type, :tinyint, limit: 1, null: false, after: :whitelist_status
    end
  end


  def down

    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      remove_column :user_kyc_details, :whitelist_status
      remove_column :user_kyc_details, :admin_action_type
    end

  end
end

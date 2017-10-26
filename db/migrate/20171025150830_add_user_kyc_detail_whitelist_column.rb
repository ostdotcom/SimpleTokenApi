class AddUserKycDetailWhitelistColumn < DbMigrationConnection
  def up

    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      add_column :user_kyc_details, :whitelist_status, :tinyint, limit: 1, null: false, after: :admin_status
    end
  end


  def down

    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      remove_column :user_kyc_details, :whitelist_status
    end

  end
end

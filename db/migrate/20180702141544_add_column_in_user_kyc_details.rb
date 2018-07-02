class AddColumnInUserKycDetails < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      add_column :user_kyc_details, :last_reopened_at, :integer, after: :last_acted_timestamp, default: 0
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      remove_column :user_kyc_details, :last_reopened_at
    end
  end
end

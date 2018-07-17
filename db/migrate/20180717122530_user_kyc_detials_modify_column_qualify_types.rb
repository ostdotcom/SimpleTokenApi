class UserKycDetialsModifyColumnQualifyTypes < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      change_column :user_kyc_details, :qualify_types, :tinyint , null: false, default: 0
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      change_column :user_kyc_details, :qualify_types, :integer, null: true
    end
  end
end

class AddColumnLastAdminIdInUserKycDetails < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      add_column :user_kyc_details, :last_admin_id, :integer, :limit => 8,  after: :last_acted_by, null: false, default: 0
    end

    UserKycDetail.where('last_acted_by > ?', 0).update_all("last_admin_id = last_acted_by")
    Rails.cache.clear

  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      remove_column :user_kyc_details, :last_admin_id
    end
  end
end

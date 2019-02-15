class AddColumnStatusToAdminSecrets < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do
      add_column :admin_secrets, :status, :tinyint, limit: 1, null: true, after: :ga_secret
    end

    AdminSecret.update_all(status: GlobalConstant::AdminSecret.active_status)
    Rails.cache.clear

    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do
      change_column :admin_secrets, :status, :tinyint, :limit => 1, null: false
    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do
      remove_column :admin_secrets, :status
    end
  end
end

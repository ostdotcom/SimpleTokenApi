class ModifyAdminTable < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do
      change_column :admins, :admin_secret_id, :integer, limit: 8, null: true
      change_column :admins, :password, :string, null: true
      change_column :admins, :status, :tinyint, limit: 1, null: true
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do
      change_column :admins, :admin_secret_id, :integer, limit: 8, null: false
      change_column :admins, :password, :string, null: false
      change_column :admins, :status, :tinyint, limit: 1, null: false
    end
  end

end
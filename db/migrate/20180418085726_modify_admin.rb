class ModifyAdmin < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do
      add_column :admins, :role, :tinyint, null: true, after: :default_client_id
    end

    Admin.update_all(role: GlobalConstant::Admin.normal_admin_role)

    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do
      change_column :admins, :role, :tinyint, null: false
    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do
      remove_column :admins, :role
    end
  end

end
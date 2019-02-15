class AddColumnSessionTime2faTimeInAdminsTable < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do
      add_column :admins, :session_inactivity_timeout, :integer, :limit => 4, after: :terms_of_use, null: true
    end

    Admin.all.each do |admin|
      admin_session_setting = AdminSessionSetting.is_active.where(client_id: admin.default_client_id).first
      admin.session_inactivity_timeout = admin_session_setting.session_inactivity_timeout
      admin.save! if admin.changed?
    end

    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do
      change_column :admins, :session_inactivity_timeout, :integer, :limit => 4, null: false
    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do
      remove_column :admins, :session_inactivity_timeout
    end
  end
end

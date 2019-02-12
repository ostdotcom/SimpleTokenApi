class AddColumnNotifiactionTypesInAdmin < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do
      add_column :admins, :notification_types, :integer, :limit => 2,  after: :status, null: false, default: 0
    end

    Admin.is_active.where(role: GlobalConstant::Admin.super_admin_role).all.each do |a_obj|
      a_obj.set_default_notification_types
      a_obj.save!
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do
      remove_column :admins, :notification_types
    end
  end
end

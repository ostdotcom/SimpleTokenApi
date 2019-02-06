class CreateAdminSessionSettings < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do

      create_table :admin_session_settings do |t|
        t.column :client_id, :integer, limit: 8, null: false
        t.column :admin_types, :tinyint, limit: 1, null: false
        t.column :session_inactivity_timeout,  :integer, limit: 4, null: false
        t.column :mfa_frequency, :integer, limit: 4, null: false
        t.column :status, :tinyint, limit: 1, null: false
        t.column :last_acted_by, :integer, limit: 8, null: true
        t.timestamps
      end

      add_index :admin_session_settings, [:client_id, :status], unique: false, name: 'client_id_status'
    end

    clients = Client.all

    clients.each do |client|
      obj = AdminSessionSetting.new(
          client_id: client.id,
          status: GlobalConstant::AdminSessionSetting.active_status,
          log_sync: true,
          source: GlobalConstant::AdminActivityChangeLogger.script_source
      )

      AdminSessionSetting.admin_types_config.map{|at,_|  obj.send("set_#{at.to_s}") }
      obj.default_setting!
      obj.save!
    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do
      drop_table :admin_session_settings
    end
  end
end

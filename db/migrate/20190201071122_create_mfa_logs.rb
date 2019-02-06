class CreateMfaLogs < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do

      create_table :mfa_logs do |t|
        t.column :admin_id, :integer, limit: 8, null: false
        t.column :ip_address, :string, limit: 40, null: false
        t.column :browser_user_agent, :string, limit: 512, null: false
        t.column :status, :tinyint, limit: 1, null: false
        t.column :token, :string, limit: 128, null: false
        t.column :last_mfa_time, :integer, limit: 4, null: false
        t.timestamps
      end

      add_index :mfa_logs, [:status, :last_mfa_time], unique: false, name: 'status_last_mfa_time'
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do
      drop_table :mfa_logs
    end
  end
end

class CreateUserActivityLog < DbMigrationConnection
  def up

    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      drop_table :user_kyc_action_logs

      create_table :user_activity_logs do |t|
        t.column :user_id, :integer, limit: 8, null: false
        t.column :admin_id, :integer, limit: 8, null: true
        t.column :log_type, :tinyint, null: false
        t.column :action, :tinyint, null: false
        t.column :action_timestamp, :bigint, null: false
        t.column :data, :string, limit: 8, null: true
        t.timestamps
      end

      add_index :user_activity_logs, [:user_id, :log_type], unique: false, name: 'uid_type'

    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      drop_table :user_activity_logs
    end
  end
end

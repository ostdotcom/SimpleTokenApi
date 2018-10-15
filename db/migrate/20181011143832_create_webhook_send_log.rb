class CreateWebhookSendLog < DbMigrationConnection
  def up
    run_migration_for_db(EstablishOstKycWebhookDbConnection.config_key) do

      create_table :webhook_send_logs do |t|
        t.column :client_id, :integer, limit: 8, null: false
        t.column :client_webhook_setting_id, :integer, limit: 8, null: false
        t.column :event_id, :bigint, null: false
        t.column :lock_id, :integer, limit: 8, null: true
        t.column :next_timestamp, :tinyint, limit: 2, null: false
        t.column :status, :tinyint, limit: 2, null: false
        t.column :failed_count, :tinyint, limit: 2, null: false, default: 0
        t.timestamps
      end

      add_index :webhook_send_logs, [:client_id, :status, :next_timestamp, :client_webhook_setting_id],
                unique: false, name: 'client_id_status_next_timestamp_cwsi'

    end
  end

  def down
    run_migration_for_db(EstablishOstKycWebhookDbConnection.config_key) do
      drop_table :webhook_send_logs
    end
  end
end

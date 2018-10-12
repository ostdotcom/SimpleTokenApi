class CreateClientWebhookSetting < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do

      create_table :client_webhook_settings do |t|
        t.column :client_id, :integer, limit: 8, null: false
        t.column :secret_key, :string, limit: 255, null: false
        t.column :status, :tinyint, limit: 2, null: false
        t.column :url, :string, limit: 255, null: false
        t.column :event_result_types, :tinyint, limit: 4, null: false, default: 0
        t.column :event_sources, :tinyint, limit: 4, null: false, default: 0
        t.column :last_acted_by, :integer, limit: 8, null: false
        t.column :last_processed_at, :integer, limit: 8, null: true
        t.timestamps
      end

      add_index :client_webhook_settings, [:client_id, :status], unique: false, name: 'client_id_status'
      add_index :client_webhook_settings, [:status, :last_processed_at], unique: false, name: 'status_last_processed_at'

    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      drop_table :client_webhook_settings
    end
  end
end

class CreateEvent < DbMigrationConnection
  def up
    run_migration_for_db(EstablishOstKycWebhookDbConnection.config_key) do

      create_table :events do |t|
        t.column :id, :bigint, primary_key: true, auto_increment: true
        t.column :uuid, :string, limit: 100, null: false
        t.column :client_id, :integer, limit: 8, null: false
        t.column :source, :tinyint, limit: 4, null: false
        t.column :name, :tinyint, limit: 4, null: false
        t.column :result_type, :tinyint, limit: 4, null: false
        t.column :timestamp, :integer, limit: 8, null: false
        t.column :data, :text, null: false
        t.timestamps
      end

      add_index :events, [:uuid], unique: true, name: 'uniq_uuid'
    end
  end

  def down
    run_migration_for_db(EstablishOstKycWebhookDbConnection.config_key) do
      drop_table :events
    end
  end
end

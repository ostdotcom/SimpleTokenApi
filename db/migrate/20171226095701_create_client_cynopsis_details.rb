class CreateClientCynopsisDetails < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      create_table :client_cynopsis_details do |t|
        t.column :client_id, :integer, limit: 8, null: false
        t.column :domain_name, :string, null: false
        t.column :token, :string, null: false
        t.column :base_url, :string, null: false
        t.column :status, :tinyint, limit: 1, null: false
        t.timestamps
      end
      add_index :client_cynopsis_details, :client_id, unique: true, name: 'uniq_client_id'
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      drop_table :client_cynopsis_details
    end
  end

end
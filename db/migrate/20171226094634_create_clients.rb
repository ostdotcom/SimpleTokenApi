class CreateClients < DbMigrationConnection

  def up

    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do

      create_table :clients do |t|
        t.column :name, :string, null: false
        t.column :status, :tinyint, limit: 1, null: false
        t.column :setup_properties, :tinyint, null: false
        t.column :api_salt, :string, null: false
        t.column :api_key, :string, null: false
        t.column :api_secret, :string, null: false
        t.timestamps
      end

      add_index :clients, :api_key, unique: true, name: 'uniq_api_key'

    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      drop_table :clients
    end
  end

end
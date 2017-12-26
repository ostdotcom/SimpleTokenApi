class CreateClientAdmins < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do

      create_table :client_admins do |t|
        t.column :client_id, :integer, limit: 8, null: false
        t.column :admin_id, :integer, limit: 8, null: false
        t.column :status, :tinyint, limit: 1, null: false
        t.column :role, :tinyint, limit: 1, null: false
        t.timestamps
      end

      add_index :client_admins, [:admin_id, :client_id], unique: false, name: 'admin_id_client_id'

    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      drop_table :client_admins
    end
  end

end
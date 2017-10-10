class CreateAdminSecrets < DbMigrationConnection
  def change

    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do

      create_table :admin_secrets do |t|
        t.column :udid, :string, null: false
        t.column :salt, :string, null: false
        t.column :ga_secret, :string, null: false
        t.column :rotation_key, :string, null: true
        t.timestamps
        t.timestamps
      end

      add_index :admin_secrets, :udid, unique: true, name: 'admin_secrets_udid'

    end

  end
end

class CreateAdminSecrets < DbMigrationConnection
  def up

    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do

      create_table :admin_secrets do |t|
        t.column :udid, :string, null: false
        t.column :login_salt, :blob, null: false #encrypted
        t.column :ga_secret, :blob, null: false #encrypted
        t.column :last_opt_at, :integer, null: true, limit: 8
        t.timestamps
        t.timestamps
      end

      add_index :admin_secrets, :udid, unique: true, name: 'admin_secrets_udid'
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do
      drop_table :admin_secrets
    end
  end

end

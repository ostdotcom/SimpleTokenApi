class CreateAdminSecrets < DbMigrationConnection
  def up

    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do

      create_table :admin_secrets do |t|
        t.column :login_salt, :blob, null: false #encrypted
        t.column :ga_secret, :blob, null: false #encrypted
        t.timestamps
      end

    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do
      drop_table :admin_secrets
    end
  end

end

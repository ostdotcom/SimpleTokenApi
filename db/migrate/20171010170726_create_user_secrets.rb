class CreateUserSecrets < DbMigrationConnection

  def up

    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do

      create_table :user_secrets do |t|
        t.column :login_salt, :blob, null: false #encrypted
        t.column :kyc_salt, :blob, default: null, null: true #encrypted
        t.timestamps
        t.timestamps
      end

    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      drop_table :user_secrets
    end
  end

end

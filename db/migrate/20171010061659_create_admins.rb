class CreateAdmins < DbMigrationConnection

  def up

    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do

      create_table :admins do |t|
        t.column :email, :string, null: false
        t.column :password, :string, null: false
        t.column :name, :string, null: false
        t.column :admin_secret_id, :integer, limit: 8, null: false
        t.column :last_otp_at, :integer, null: true, limit: 8
        t.column :status, :tinyint, limit: 1, null: false, default: 1
        t.timestamps
      end

      add_index :admins, :email, unique: true, name: 'uniq_email'

    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do
      drop_table :admins
    end
  end

end

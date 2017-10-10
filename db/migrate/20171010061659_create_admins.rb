class CreateAdmins < DbMigrationConnection

  def change

    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do

      create_table :admins do |t|
        t.column :email, :string, null: false
        t.column :password, :string, null: false
        t.column :status, :tinyint, limit: 1, null: false, default: 1
        t.column :udid, :string, null: true
        t.timestamps
        t.timestamps
      end

      add_index :admins, :email, unique: true, name: 'admin_email'

    end

  end

end

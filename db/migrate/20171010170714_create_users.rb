class CreateUsers < DbMigrationConnection

  def up

    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do

      create_table :users do |t|
        t.column :email, :string, null: false
        t.column :password, :string, null: false
        t.column :user_secret_id, :initeger, null: true
        t.column :status, :tinyint, limit: 1, null: false, default: 1
        t.timestamps
        t.timestamps
      end

      add_index :users, :email, unique: true, name: 'user_email'

    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      drop_table :users
    end
  end

end

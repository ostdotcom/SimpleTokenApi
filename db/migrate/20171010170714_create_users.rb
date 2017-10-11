class CreateUsers < DbMigrationConnection

  def up

    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do

      create_table :users do |t|
        t.column :email, :string, null: false
        t.column :password, :string, null: false
        t.column :user_secret_id, :integer, limit: 8, null: false
        t.column :first_name, :string, null: true
        t.column :last_name, :string, null: true
        t.column :bt_name, :string, null: true
        t.column :properties, :tinyint, null: false, default: 0
        t.column :status, :tinyint, limit: 1, null: false, default: 1
        t.timestamps
        t.timestamps
      end

      add_index :users, :email, unique: true, name: 'uniq_email'
      add_index :users, :bt_name, unique: true, name: 'uniq_bt_name'

    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      drop_table :users
    end
  end

end

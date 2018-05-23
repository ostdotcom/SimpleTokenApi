class CreateDeletedUsers < DbMigrationConnection
  def up

    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do

      create_table :deleted_users do |t|
        t.column :client_id, :integer, null: false
        t.column :deleted_by_admin, :integer, null: false
        t.column :email, :string, null: false
        t.column :user_id, :integer, null: false
        t.column :status, :tinyint, limit: 1, null: false, default: 1
        t.timestamps
      end

    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      drop_table :deleted_users
    end
  end
end

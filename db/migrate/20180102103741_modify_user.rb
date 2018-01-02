class ModifyUser < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      change_column :users, :user_secret_id, :integer, null: true
      change_column :users, :password, :string, null: true
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      change_column :users, :user_secret_id, :integer, null: false
      change_column :users, :password, :string, null: false
    end
  end

end
class ModifyUserIndex < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      remove_index :users, name: :uniq_email
      add_index :users, [:client_id, :email], unique: true, name: 'uniq_client_id_and_email'
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      add_index :users, [:email],  unique: true, name: 'uniq_email'
      remove_index :users, name: :uniq_client_id_and_email
    end
  end

end
class AddLastLoggedInAtColumnInUsers < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      add_column :users, :last_logged_in_at, :integer, after: :properties, :null => true
    end

    User.where.not(password: [nil, ""]).update_all(last_logged_in_at: Time.now.to_i - 1.hours)
    Rails.cache.clear
  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      remove_column :users, :last_logged_in_at
    end
  end
end

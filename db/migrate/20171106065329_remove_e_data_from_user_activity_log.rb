class RemoveEDataFromUserActivityLog < DbMigrationConnection

  def up

    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      remove_column :user_activity_logs, :data
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      add_column :user_activity_logs, :data, :text, null: true, after: :data
    end
  end
end

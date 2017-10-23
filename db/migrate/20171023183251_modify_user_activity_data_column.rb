class ModifyUserActivityDataColumn < DbMigrationConnection
  def up

    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      change_column :user_activity_logs, :data, :text, null: true
    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
    end

  end
end

class AddColumnPosBonusPercentageInUsers < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      add_column :users, :pos_bonus_percentage, :float, after: :status
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      remove_column :users, :pos_bonus_percentage
    end
  end

end

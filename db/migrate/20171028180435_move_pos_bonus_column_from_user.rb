class MovePosBonusColumnFromUser < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      change_column :pos_bonus_emails, :bonus_percentage, :decimal, precision: 5, scale: 2
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      change_column :pos_bonus_emails, :bonus_percentage, :float
    end
  end

end

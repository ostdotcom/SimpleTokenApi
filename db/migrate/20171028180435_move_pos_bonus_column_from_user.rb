class MovePosBonusColumnFromUser < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      remove_column :users, :pos_bonus_percentage
      add_column :user_kyc_details, :pos_bonus_percentage, :decimal, precision: 5, scale: 2, after: :token_sale_participation_phase
    end

    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      change_column :pos_bonus_emails, :bonus_percentage, :decimal, precision: 5, scale: 2
    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      add_column :users, :pos_bonus_percentage, :decimal, precision: 5, scale: 2, after: :status
      remove_column :user_kyc_details, :pos_bonus_percentage
    end

    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      change_column :pos_bonus_emails, :bonus_percentage, :float
    end

  end

end

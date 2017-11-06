class AddAlternateTokenIdInUserKycDetailsTable < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      add_column :user_kyc_details, :alternate_token_id_for_bonus, :integer, limit: 8, after: :pos_bonus_percentage
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      remove_column :user_kyc_details, :alternate_token_id_for_bonus
    end
  end

end

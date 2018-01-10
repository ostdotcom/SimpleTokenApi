class AlterBonusTokenLog < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      add_column :bonus_token_logs, :ethereum_address_for_bonus_distribution, :string, limit: 255, null: true, after: :ethereum_address
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      remove_column :bonus_token_logs, :ethereum_address_for_bonus_distribution
    end
  end

end

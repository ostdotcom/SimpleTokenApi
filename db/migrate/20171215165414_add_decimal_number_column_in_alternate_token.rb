class AddDecimalNumberColumnInAlternateToken < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      add_column :alternate_tokens, :number_of_decimal, :integer, null: true, after: :contract_address
    end

    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      add_column :alt_coin_bonus_logs, :number_of_decimal,:integer, null: true, after: :alt_token_amount_in_wei
    end

  end

  def down

    run_migration_for_db(EstablishSimpleTokenLogDbConnection.config_key) do
      remove_column :alternate_tokens, :number_of_decimal
    end

    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      remove_column :alt_coin_bonus_logs, :number_of_decimal
    end

  end

end
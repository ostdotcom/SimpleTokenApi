class RenameEthAdjustmentColumnName < DbMigrationConnection

  def up

    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      rename_column :bonus_token_logs, :eth_adjustment_bonus_percent, :discretionary_bonus_percent
      rename_column :bonus_token_logs, :eth_adjustment_bonus_in_st, :discretionary_bonus_in_st

      rename_column :pre_sale_purchase_logs, :eth_adjustment_bonus_percent, :discretionary_bonus_percent
    end

  end

  def down
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      rename_column :bonus_token_logs, :discretionary_bonus_percent, :eth_adjustment_bonus_percent
      rename_column :bonus_token_logs, :discretionary_bonus_in_st, :eth_adjustment_bonus_in_st

      rename_column :pre_sale_purchase_logs, :discretionary_bonus_percent, :eth_adjustment_bonus_percent
    end
  end

end

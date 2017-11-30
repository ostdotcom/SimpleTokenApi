class CreateAltCoinBonusLog < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      create_table :alt_coin_bonus_logs do |t|
        t.column :ethereum_address, :string, limit: 255, null: false
        t.column :alt_token_name, :string, limit: 255, null: false
        t.column :ether_wei_value, :decimal, precision: 30, scale: 0, null: false
        t.column :altcoin_bonus_wei_value, :decimal, precision: 30, scale: 0, null: false
        t.timestamps
      end
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      drop_table :alt_coin_bonus_logs
    end
  end

end


class CreateBonusTokenLog < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      create_table :bonus_token_logs do |t|
        t.column :ethereum_address, :string, limit: 255, null: false
        t.column :st_wei_value, :decimal, precision: 30, scale: 0, null: false
        t.column :st_total_bonus_wei_value, :decimal, precision: 30, scale: 0, null: false
        t.column :pos_bonus, :integer, null: false, default: 0
        t.column :community_bonus_percent, :integer, null: false, default: 0
        t.column :eth_adjustment_bonus, :integer, null: false, default: 0
        t.column :is_pre_sale, :integer, limit: 1, null: false
        t.column :st_pre_sale_bonus_wei_value, :decimal, precision: 30, scale: 0, null: false, default: 0
        t.timestamps
      end
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      drop_table :bonus_token_logs
    end
  end

end


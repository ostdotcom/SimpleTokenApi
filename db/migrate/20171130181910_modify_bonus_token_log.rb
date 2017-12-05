class ModifyBonusTokenLog < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      drop_table :bonus_token_logs

      create_table :bonus_token_logs do |t|
        t.column :ethereum_address, :string, limit: 255, null: false
        t.column :purchase_in_st_wei, :decimal, precision: 30, scale: 0, null: false
        t.column :purchase_in_st, :decimal, precision: 30, scale: 10, null: false
        t.column :total_bonus_in_wei, :decimal, precision: 30, scale: 0, null: false
        t.column :total_bonus_value_in_st, :decimal, precision: 30, scale: 10, null: false
        t.column :pos_bonus_percent, :integer, null: false, default: 0
        t.column :pos_bonus_in_st, :decimal, precision: 30, scale: 10, null: false
        t.column :community_bonus_percent, :integer, null: false, default: 0
        t.column :community_bonus_in_st, :decimal, precision: 30, scale: 10, null: false
        t.column :eth_adjustment_bonus_percent, :integer, null: false, default: 0
        t.column :eth_adjustment_bonus_in_st, :decimal, precision: 30, scale: 10, null: false
        t.column :is_pre_sale, :integer, limit: 1, null: false
        t.column :is_ingested_in_trustee, :integer, limit: 1, null: false
        t.column :pre_sale_bonus_in_st, :decimal, precision: 30, scale: 10, null: false, default: 0
        t.timestamps
      end
    end
  end

  def down
  end

end


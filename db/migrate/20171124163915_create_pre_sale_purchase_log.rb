class CreatePreSalePurchaseLog < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      create_table :pre_sale_purchase_logs do |t|
        t.column :ethereum_address, :string, limit: 255, null: false
        t.column :st_wei_value, :decimal, precision: 30, scale: 0, null: false
        t.column :st_bonus_wei_value, :decimal, precision: 30, scale: 0, null: false
        t.column :eth_adjustment_bonus_percent, :integer, null: false, default: 0
      end
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      drop_table :pre_sale_purchase_logs
    end
  end

end

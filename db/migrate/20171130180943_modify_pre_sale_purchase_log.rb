class ModifyPreSalePurchaseLog < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do

      remove_column :pre_sale_purchase_logs, :st_wei_value
      remove_column :pre_sale_purchase_logs, :st_bonus_wei_value

      add_column :pre_sale_purchase_logs, :st_base_token, :integer, after: :ethereum_address
      add_column :pre_sale_purchase_logs, :st_bonus_token, :integer, after: :st_base_token
      add_column :pre_sale_purchase_logs, :is_ingested_in_trustee, :string, limit: 10, after: :eth_adjustment_bonus_percent

      add_index :pre_sale_purchase_logs, [:ethereum_address], unique: true, name: 'ETHEREUM_ADDRESS_UNIQUE_INDEX'

    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      add_column :pre_sale_purchase_logs, :st_wei_value, :decimal, precision: 30, scale: 0, null: false, after: :ethereum_address
      add_column :pre_sale_purchase_logs, :st_bonus_wei_value, :decimal, precision: 30, scale: 0, null: false, after: :st_wei_value

      remove_column :pre_sale_purchase_logs, :st_base_token
      remove_column :pre_sale_purchase_logs, :st_bonus_token
      remove_column :pre_sale_purchase_logs, :is_ingested_in_trustee
      remove_index :pre_sale_purchase_logs, name: 'ETHEREUM_ADDRESS_UNIQUE_INDEX'

    end
  end
end




class CreatePurchaseLog < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      create_table :purchase_logs do |t|
        t.column :ethereum_address, :string, limit: 255, null: false
        t.column :ether_wei_value, :decimal, precision: 30, scale: 0, null: false
        t.column :usd_value, :decimal, precision: 15, scale: 2, null: false
        t.column :st_wei_value, :decimal, precision: 30, scale: 0, null: false
        t.column :block_creation_timestamp, :integer, null: false
        t.column :pst_day_start_timestamp, :integer, null: false
        t.timestamps
      end

      add_index :purchase_logs, [:ethereum_address], unique: false, name: 'ethereum_address_index'
      add_index :purchase_logs, [:pst_day_start_timestamp], unique: false, name: 'pst_day_start_timestamp_index'
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      drop_table :purchase_logs
    end
  end

end

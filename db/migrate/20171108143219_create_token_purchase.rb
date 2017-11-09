class CreateTokenPurchase < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      create_table :token_purchases do |t|
        t.column :ethereum_address, :string, limit: 255, null: false
        t.column :ether_value, :decimal, null: false # , precision: 5, scale: 2,
        t.column :usd_value, :decimal, null: false
        t.column :simple_token_value, :bigint, null: false
        t.column :purchase_date, :date, null: false    #as per time zone . cannot be changed later
        t.timestamps
      end

      # TODO: INDEX ON DATE INSTEAD
      add_index :token_purchases, [:ethereum_address], unique: false, name: 'ethereum_address_index'
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      drop_table :token_purchases
    end
  end

end

class CreateClientTokenSaleDetail < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      create_table :client_token_sale_details do |t|
        t.column :client_id, :integer, limit: 8, null: false
        t.column :sale_start_timestamp, :integer, limit: 8, null: false
        t.column :sale_end_timestamp, :integer, limit: 8, null: false
        t.column :ethereum_deposit_address, :string, limit: 355, null: true
        t.column :status, :tinyint, limit: 1, null: false
        t.timestamps
      end
      add_index :client_token_sale_details, :client_id, unique: true, name: 'uniq_client_id'
    end

    # ClientTokenSaleDetail.create!(
    #     client_id: GlobalConstant::TokenSale.st_token_sale_client_id,
    #     sale_start_timestamp: GlobalConstant::TokenSale.early_access_start_date,
    #     sale_end_timestamp: GlobalConstant::TokenSale.general_access_end_date,
    #     ethereum_deposit_address: GlobalConstant::TokenSale.st_token_sale_ethereum_address,
    #     status: GlobalConstant::ClientTokenSaleDetail.active_status
    # )

  end

  def down
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      drop_table :client_token_sale_details
    end
  end

end

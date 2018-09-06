class AddTokenNameInClientTokenSale < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      add_column :client_token_sale_details, :token_name, :string, null: true, after: :client_id
      add_column :client_token_sale_details, :token_symbol, :string, null: true, after: :token_name
    end
    ClientTemplate.where(template_type: 1).all.each do |ct|
      ClientTokenSaleDetail.where(client_id: ct.client_id).update(token_name: ct.data[:account_name], token_symbol: ct.data[:account_name_short])
    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      remove_column :client_token_sale_details, :token_name
      remove_column :client_token_sale_details, :token_symbol
    end
  end
end

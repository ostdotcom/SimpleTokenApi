class CreateClientWebHostDetail < DbMigrationConnection

  def up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      create_table :client_web_host_details do |t|
        t.column :client_id, :integer, limit: 8, null: false
        t.column :domain, :string, limit: 50, null: false
        t.column :status, :tinyint, limit: 1, null: false
        t.timestamps
      end
      add_index :client_web_host_details, :client_id, unique: true, name: 'uniq_client_id'
      add_index :client_web_host_details, :domain, unique: true, name: 'uniq_domain'
    end

    domain = Rails.env.production? ? "sale.simpletoken.org" : (Rails.env.staging? ? "kyc.sandboxost.com" : "kyc.developmentost.com")

    ClientWebHostDetail.create!(client_id:  GlobalConstant::TokenSale.st_token_sale_client_id,
                                domain: domain,
                                status: GlobalConstant::ClientWebHostDetail.active_status)

  end

  def down
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      drop_table :client_web_host_details
    end
  end

end

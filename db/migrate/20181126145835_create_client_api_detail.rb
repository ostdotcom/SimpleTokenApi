class CreateClientApiDetail < DbMigrationConnection
  def up
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do

      create_table :client_api_details do |t|
        t.column :client_id, :integer, limit: 8, null: false
        t.column :api_key, :string, null: false
        t.column :api_secret, :string, null: false
        t.column :status, :tinyint, limit: 2, null: false
        t.timestamps
      end

      add_index :client_api_details, [:client_id, :status], unique: false, name: 'client_id_status'
      add_index :client_api_details, [:api_key], unique: true, name: 'u_api_key'


      Client.all.each do |client|
        ClientApiDetail.create!({
                                    client_id: client.id,
                                    api_key: client.api_key,
                                    api_secret: client.api_secret,
                                    status: GlobalConstant::ClientApiDetail.active_status
                                })
      end


    end
  end

  def down
    run_migration_for_db(EstablishSimpleTokenClientDbConnection.config_key) do
      drop_table :client_api_details
    end
  end

end

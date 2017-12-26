class ModifyColumnClientIdInTables < DbMigrationConnection

  def up

    # Add client for simpletoken and update all tables with client id

    client = Client.create(name: 'simpletoken', status: GlobalConstant::Client.active_status, setup_properties: 7, api_key: SecureRandom.hex, api_secret: SecureRandom.hex)
    client_id = client.id


    ClientCynopsisDetail.create(client_id: client_id, domain_name: GlobalConstant::Cynopsis.domain_name,
                                token: GlobalConstant::Cynopsis.token, base_url: GlobalConstant::Cynopsis.base_url,
                                status: GlobalConstant::ClientCynopsisDetail.active_status)

    ClientPepoCampaignDetail.create(client_id: client_id, api_key: GlobalConstant::PepoCampaigns.api_key,
                                    api_secret: GlobalConstant::PepoCampaigns.api_secret,
                                    status: GlobalConstant::ClientPepoCampaignDetail.active_status)

    Admin.all.each do |admin|

      ClientAdmin.create(client_id: client_id, admin_id: admin.id,
                         role: GlobalConstant::ClientAdmin.normal_admin_role,
                         status: GlobalConstant::ClientAdmin.active_status)

    end

    Admin.update_all(default_client_id: client_id)
    UserKycDetail.update_all(client_id: client_id)
    User.update_all(client_id: client_id)


    # modify client id to null false

    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do
      change_column :admins, :default_client_id, :integer, null: false
    end

    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      change_column :user_kyc_details, :client_id, :integer, null: false
      change_column :users, :client_id, :integer, null: false
    end

  end

  def down

    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do
      change_column :admins, :default_client_id, :integer, null: true
    end

    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      change_column :user_kyc_details, :client_id, :integer, null: true
      change_column :users, :client_id, :integer, null: true
    end

  end

end
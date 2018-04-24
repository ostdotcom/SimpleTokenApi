class ModifyColumnClientIdInTables < DbMigrationConnection

  def up

    params = {
        "client_name" => "simpletoken",
        "cynopsis" => {
            "domain_name" => GlobalConstant::Cynopsis.domain_name,
            "token" => GlobalConstant::Cynopsis.token,
            "base_url" =>  GlobalConstant::Cynopsis.base_url
        },
        "pepo_campaign" => {
            "api_key" => GlobalConstant::PepoCampaigns.api_key,
            "api_secret" => GlobalConstant::PepoCampaigns.api_secret
        },
        "whitelist" => {
            "contract_address" => GlobalConstant::TokenSale.st_token_sale_ethereum_address,
            "whitelister_address" => '0x6AF98e753f79353eb997ADBe6c2E3BF3565b0142'
        }
    }

    # update rake task
    system("rake RAILS_ENV=#{Rails.env} onetimer:add_client params='#{params.to_json}'")

    client_id = Client.first.id

    Admin.update_all(default_client_id: client_id)
    UserKycDetail.update_all(client_id: client_id)
    User.update_all(client_id: client_id)
    KycWhitelistLog.update_all(client_id: client_id)
    EmailServiceApiCallHook.update_all(client_id: client_id)

    # modify client id to null false

    run_migration_for_db(EstablishSimpleTokenAdminDbConnection.config_key) do
      change_column :admins, :default_client_id, :integer, null: false
    end

    run_migration_for_db(EstablishSimpleTokenUserDbConnection.config_key) do
      change_column :user_kyc_details, :client_id, :integer, null: false
      change_column :users, :client_id, :integer, null: false
    end

    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      change_column :kyc_whitelist_logs, :client_id, :integer, null: false
    end

    run_migration_for_db(EstablishSimpleTokenEmailDbConnection.config_key) do
      change_column :email_service_api_call_hooks, :client_id, :integer, null: false
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

    run_migration_for_db(EstablishSimpleTokenContractInteractionsDbConnection.config_key) do
      change_column :kyc_whitelist_logs, :client_id, :integer, null: true
    end

    run_migration_for_db(EstablishSimpleTokenEmailDbConnection.config_key) do
      change_column :email_service_api_call_hooks, :client_id, :integer, null: true
    end

  end

end
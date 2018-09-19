namespace :onetimer do


  # params = {
  #     "client_plan" => {
  #       "add_ons" => ['whitelisting', 'frontend'],
  #       "kyc_submissions_count" => 100
  #     },
  #     "super_admin" => {
  #         "email" => "aman@ost.com",
  #         "password" => "aman@123",
  #         "name" => "aman"
  #     },
  #     "double_opt_in" => 1,
  #     "client_name" => "pankajkyc.developmentost.com",
  #     "cynopsis" => {
  #         "email_id" =>  'aman@ost.com',
  #         "domain_name" => GlobalConstant::Cynopsis.domain_name,
  #         "token" => GlobalConstant::Cynopsis.token,
  #         "base_url" => GlobalConstant::Cynopsis.base_url
  #     },
  #     "pepo_campaign" => {
  #         "api_key" => '0455fbd02e9512168211903ff25094d8',
  #         "api_secret" => '4c1b4ec0983ab6b1e37d1c1fc31de5e6'
  #     },
  #     "whitelist" => {
  #         "contract_address" => '0x81662ab3f307b6d4b777bb5996f0ba9659ab6d27',
  #         "whitelister_address" => '0x31f2c12ef04683cb8fa5a7b145f34876a5271660'
  #     },
  #     "web_host" => {
  #         "domain" => "pepokyc.developmentost.com"
  #     },
  #     "token_sale_details" => {
  #         "token_name" => "Company",
  #         "token_symbol" => 'CMP',
  #         "ethereum_deposit_address" => "0xEc9859B0B3B4652aD5e264776a79E544b76aman2",
  #     },
  #     "kyc_config" => {
  #         "kyc_fields" => [
  #             "first_name",
  #             "last_name",
  #             "birthdate",
  #             "country",
  #             "ethereum_address",
  #             "document_id_number",
  #             "nationality",
  #             "document_id_file_path",
  #             "selfie_file_path",
  #             "residence_proof_file_path",
  #             "investor_proof_files_path",
  #             # "street_address",
  #             # "city",
  #             "state",
  #             # "postal_code"
  #         ]
  #     }
  # }

  #   system("rake RAILS_ENV=#{Rails.env} onetimer:add_client params='
  # {\"client_name\":\"thirdtoken\",\"cynopsis\":{\"domain_name\":\"SIMPLETOKEN\",\"token\":\"11e73a1b-b41f-425d-b10e-36dfcbdab6ed-1234\",\"base_url\":\"https://d1.cynopsis-solutions.com/artemis_simpletoken\"},\"pepo_campaign\":{\"api_key\":\"0455fbd02e9512168211903ff25094d8\",\"api_secret\":\"4c1b4ec0983ab6b1e37d1c1fc31de5e6\"},\"whitelist\":{\"contract_address\":\"0x6AF98e753f79353eb997ADBe6c2E3BF3565b0142\"}}
  # '")


  # params = params.to_json
  # rake RAILS_ENV=development onetimer:add_client params="{\"client_name\":\"simpletoken\",\"cynopsis\":{\"domain_name\":\"bar\",\"token\":\"notmuch\",\"base_url\":\"bar\"},\"pepo_campaign\":{\"api_key\":\"bar\",\"api_secret\":\"notmuch\"}}"

  task :add_client => :environment do

    params = JSON.parse(ENV['params'])
    super_admin = params["super_admin"]
    cynopsis_data = params["cynopsis"]
    pepo_campaign_data = params["pepo_campaign"]
    whitelist_data = params["whitelist"]
    web_host_data = params["web_host"]
    token_sale_details = params["token_sale_details"]
    kyc_config = params["kyc_config"]
    client_plan = params["client_plan"]

    fail 'client_plan issue' if client_plan.blank? || (client_plan['kyc_submissions_count'].to_i == 0)

    invalid_add_ons = client_plan['add_ons'] - ClientPlan.add_ons_config.keys
    fail "Invalid Add On-#{invalid_add_ons}" if invalid_add_ons.present?

    fail 'Whitelist cannot be setup if Ethereum Address is not selected for kyc form' if whitelist_data.present? &&
        kyc_config["kyc_fields"].exclude?(GlobalConstant::ClientKycConfigDetail.ethereum_address_kyc_field)

    fail 'token cannot be blank for cynopsis' if cynopsis_data['token'].blank? || token_sale_details.blank? || kyc_config.blank?
    fail "cynopsis email id(#{cynopsis_data['email_id']}) is not valid " if cynopsis_data['email_id'].blank? || !Util::CommonValidator.is_valid_email?(cynopsis_data['email_id'])

    if pepo_campaign_data.present?
      fail 'api_key cannot be blank for pepo_campaign' if pepo_campaign_data['api_key'].blank?
      fail 'api_secret cannot be blank for pepo_campaign' if pepo_campaign_data['api_secret'].blank?
    end

    if whitelist_data.present? && (whitelist_data['contract_address'].blank? || whitelist_data['whitelister_address'].blank?)
      fail 'contract_address or  whitelister_address cannot be blank for whitelist_data'
    end

    if super_admin.blank? || super_admin['email'].blank? || super_admin['password'].blank? ||
        super_admin['name'].blank? || !Util::CommonValidator.is_valid_email?(super_admin['email'])
      fail 'Invalid Super Admin Email'
    end

    setup_properties_val = 1
    setup_properties_val += 2 if pepo_campaign_data.present?
    setup_properties_val += 4 if whitelist_data.present?
    setup_properties_val += 8 if web_host_data.present?
    setup_properties_val += 16 if params['double_opt_in'].to_i == 1


    #get cmk key and text
    kms_login_client = Aws::Kms.new('saas', 'saas')
    resp = kms_login_client.generate_data_key
    return resp unless resp.success?

    api_salt_e = resp.data[:ciphertext_blob]
    api_salt_d = resp.data[:plaintext]

    client_api_secret_d = SecureRandom.hex

    r = LocalCipher.new(api_salt_d).encrypt(client_api_secret_d)
    return r unless r.success?

    api_secret_e = r.data[:ciphertext_blob]
    api_key = SecureRandom.hex

    client = Client.create(name: params["client_name"], status: GlobalConstant::Client.active_status,
                           setup_properties: setup_properties_val, api_key: api_key, api_salt: api_salt_e,
                           api_secret: api_secret_e)
    client_id = client.id

    super_admin_obj = Admin.add_admin(client_id, super_admin['email'], super_admin['password'], super_admin['name'], true)

    ckps_obj = ClientKycPassSetting.new(client_id: client_id, face_match_percent: 100,
                                        approve_type: GlobalConstant::ClientKycPassSetting.manual_approve_type,
                                        status: GlobalConstant::ClientKycPassSetting.active_status,
                                        created_at: Time.now - ClientManagement::UpdateAutoApproveSetting::TIMEFRAME_FOR_SETTING_UPDATE_IN_MINUTES.minutes)

    ClientKycPassSetting.ocr_comparison_fields_config.keys.each do |key|
      ckps_obj.send("set_#{key}")
    end
    ckps_obj.save!


    r = LocalCipher.new(api_salt_d).encrypt(cynopsis_data['token'])
    return r unless r.success?

    cynopsis_token_e = r.data[:ciphertext_blob]

    ClientCynopsisDetail.create(client_id: client_id, email_id: cynopsis_data['email_id'], domain_name: cynopsis_data['domain_name'],
                                token: cynopsis_token_e, base_url: cynopsis_data['base_url'],
                                status: GlobalConstant::ClientCynopsisDetail.active_status)

    if pepo_campaign_data.present?
      r = LocalCipher.new(api_salt_d).encrypt(pepo_campaign_data['api_secret'])
      return r unless r.success?

      pepo_campaign_api_secret_e = r.data[:ciphertext_blob]

      ClientPepoCampaignDetail.create(client_id: client_id, api_key: pepo_campaign_data['api_key'],
                                      api_secret: pepo_campaign_api_secret_e,
                                      status: GlobalConstant::ClientPepoCampaignDetail.active_status)

    end

    if web_host_data.present?
      ClientWebHostDetail.create!(client_id: client_id, domain: web_host_data["domain"],
                                  status: GlobalConstant::ClientWebHostDetail.active_status)

      ClientManagement::SetupDefaultClientCustomDraft.new(admin_id: super_admin_obj.id, client_id: client_id).perform
    end

    ethereum_deposit_address = token_sale_details['ethereum_deposit_address']
    ethereum_deposit_address_e = nil

    if ethereum_deposit_address.present?
      encryptor_obj = LocalCipher.new(GlobalConstant::SecretEncryptor.ethereum_deposit_address_secret_key)
      r = encryptor_obj.encrypt(ethereum_deposit_address)
      fail r unless r.success?
      ethereum_deposit_address_e = r.data[:ciphertext_blob]
    end

    ClientTokenSaleDetail.create!(
        client_id: client_id,
        sale_start_timestamp: Time.now.to_i,
        registration_end_timestamp: Time.now.to_i + 1.month.to_i,
        sale_end_timestamp: Time.now.to_i + 1.month.to_i,
        token_name: token_sale_details['token_name'],
        token_symbol: token_sale_details['token_symbol'],
        ethereum_deposit_address: ethereum_deposit_address_e,
        status: GlobalConstant::ClientTokenSaleDetail.active_status
    )

    ClientKycConfigDetail.add_config(client_id: client_id, kyc_fields: kyc_config["kyc_fields"],
                                     residency_proof_nationalities: [],
                                     blacklisted_countries: []
    )

    ClientWhitelistDetail.create(client_id: client_id, contract_address: whitelist_data['contract_address'],
                                 whitelister_address: whitelist_data['whitelister_address'],
                                 status: GlobalConstant::ClientWhitelistDetail.active_status) if whitelist_data.present?

    cp = ClientPlan.new(client_id: client_id,
                        kyc_submissions_count: client_plan['kyc_submissions_count'].to_i,
                        status: GlobalConstant::ClientPlan.active_status)

    client_plan['add_ons'].each do |add_on|
      cp.send("set_#{add_on}")
    end
    cp.save!


    puts "client_id: #{client_id}"
  end

end

namespace :onetimer do

  # NOTE::
  # On sandbox - uuid should start with 'sandbox_'
  # when pulled to production - in web host domain "sandbox" is removed

  # Special Handling for development/staging since there is no sandbox
  #   Mandatory-email should have suffix 'sandbox@' which gets replaced on production pull
  #   Mandatory-web host domain should have prefix 'sandbox' which gets replaced on production pull




  # params = {
  #         "client_plan" => {
  #             "add_ons" => ['whitelist', 'custom_front_end'],
  #             "kyc_submissions_count" => 100
  #         },
  #         "super_admins" => [{
  #                                "email" => "yogesh+peposandbox@ost.com",
  #                                "password" => "11221122",
  #                                "name" => "yogesh"
  #                            }],
  #         "double_opt_in" => 1,
  #         "client_name" => "Pepo",
  #         "pepo_campaign" => {
  #             "api_key" => '0455fbd02e9512168211903ff25094d8',
  #             "api_secret" => '4c1b4ec0983ab6b1e37d1c1fc31de5e6'
  #         },
  #         "web_host" => {
  #             "domain" => "sandboxpepokyc.stagingost.com"
  #         },
  #         "token_sale_details" => {
  #             "token_name" => "Pepo coin",
  #             "token_symbol" => 'PEPO',
  #             "sale_start_timestamp" =>  nil,
  #             "registration_end_timestamp" =>  nil,
  #             "sale_end_timestamp" =>  nil,
  #         },
  #         "kyc_config" => {
  #             "kyc_fields" => [
  #                 "first_name",
  #                 "last_name",
  #                 "birthdate",
  #                 "country",
  #                 "ethereum_address",
  #                 "document_id_number",
  #                 "nationality",
  #                 "document_id_file_path",
  #                 "selfie_file_path",
  #                 "residence_proof_file_path",
  #                 "investor_proof_files_path",
  #                 "street_address",
  #                 "city",
  #                 "state",
  #                 "postal_code",
  #                 "estimated_participation_amount"
  #             ],
  #             "extra_kyc_fields" =>  {
  #                 referral: {
  #                     label: 'referral code',
  #                     validation: {
  #                         required: 1
  #                     },
  #                     data_type: 'text'
  #                 },
  #                 referral_1: {
  #                     label: 'referral code 1',
  #                     validation: {
  #                         required: 0
  #                     },
  #                     data_type: 'text'
  #                 },
  #                 referral_2: {
  #                     label: 'referral code 2',
  #                     validation: {
  #                         required: 1
  #                     },
  #                     data_type: 'text'
  #                 }
  #
  #             },
  #             "auto_send_kyc_emails" => [
  #                 "send_approve_email",
  #                 "send_deny_email",
  #                 "send_report_issue_email"
  #             ]
  #             "residency_proof_nationalities" => [],
  #             "blacklisted_countries" => []
  #         }
  #     }

  #  for production account setup pass only uuid of sandbox account
  # params = {
  #     "uuid" => "abc"
  # }

  #   system("rake RAILS_ENV=#{Rails.env} onetimer:add_client params='
  # {\"client_name\":\"thirdtoken\",\"pepo_campaign\":{\"api_key\":\"0455fbd02e9512168211903ff25094d8\",\"api_secret\":\"4c1b4ec0983ab6b1e37d1c1fc31de5e6\"}
  # '")


  # params = params.to_json
  # rake RAILS_ENV=development onetimer:add_client params="{\"client_plan\":{\"add_ons\":[\"whitelist\",\"custom_front_end\"],\"kyc_submissions_count\":100},\"super_admin\":{\"email\":\"tejas+7@ost.com\",\"password\":\"tejas123\",\"name\":\"tejas\"},\"double_opt_in\":1,\"client_name\":\"test2\",\"pepo_campaign\":{\"api_key\":\"0455fbd02e9512168211903ff25094d8\",\"api_secret\":\"4c1b4ec0983ab6b1e37d1c1fc31de5e6\"},\"web_host\":{\"domain\":\"tejaskyc.developmentost.com\"},\"token_sale_details\":{\"token_name\":\"Tejas\",\"token_symbol\":\"T777\"},\"kyc_config\":{\"kyc_fields\":[\"first_name\",\"last_name\",\"birthdate\",\"country\",\"ethereum_address\",\"document_id_number\",\"nationality\",\"document_id_file_path\",\"selfie_file_path\",\"residence_proof_file_path\",\"investor_proof_files_path\",\"state\"]}}"

  task :add_client => :environment do
    params = JSON.parse(ENV['params'])
    uuid = params["uuid"]

    fail 'uuid not given' if (Rails.env.production? && uuid.blank?)
    fail 'uuid cannot be passed' if (Rails.env.sandbox? && uuid.present?)

    if (Rails.env.staging? || Rails.env.development?) && uuid.blank?
      fail "sandbox client in staging/development should have sandbox as prefix in domain" if params["web_host"].present? && !params["web_host"]["domain"].starts_with?("sandbox")

      params["super_admins"].each do |super_admin|
        fail "sandbox client in staging/development should have format->email+sandbox@ost.com for emails" unless
            super_admin['email'].to_s.match?(GlobalConstant::Admin.sandbox_email_suffix)
      end
    end

    if uuid.present?
      params = get_sandbox_account_settings(uuid)
      params["web_host"]["domain"].gsub!("sandbox", "") if params["web_host"].present?

      params["super_admins"].each do |super_admin|
        super_admin['email'].gsub!(GlobalConstant::Admin.sandbox_email_suffix, "@")
      end if (Rails.env.staging? || Rails.env.development?)

    else
      uuid = GlobalConstant::Client.sandbox_prefix_uuid + "#{SecureRandom.hex}_#{Time.now.to_i}"
      params["entity_type_and_data_hash"] = GlobalConstant::CmsConfigurator.custom_default_template_data if params["web_host"].present?
    end

    setup_account(uuid, params)
  end

  def get_sandbox_account_settings(uuid)
    environment = Rails.env.production? ? GlobalConstant::RailsEnvironment.sandbox : Rails.env
    puts "::Fetching details of sandbox account from environment-#{environment}::"

    r = Request::SandboxApi::FetchClientSetupSetting.new.perform(environment, {uuid: uuid})
    fail "#{r.to_json.inspect}" unless r.success?

    puts "::Clients settins fetched::"

    r.data['client_setting']
  end

  def setup_account(uuid, params)
    puts "::Started account setup::"

    puts "\tValidation started"

    super_admins = params["super_admins"]

    pepo_campaign_data = params["pepo_campaign"]
    web_host_data = params["web_host"]
    token_sale_details = params["token_sale_details"]
    kyc_config = params["kyc_config"]
    client_plan = params["client_plan"]

    has_whitelist_ad_on = client_plan['add_ons'].include?(GlobalConstant::ClientPlan.whitelist_add_ons)

    fail 'client_plan issue' if client_plan.blank? || (client_plan['kyc_submissions_count'].to_i == 0)

    invalid_add_ons = client_plan['add_ons'] - ClientPlan.add_ons_config.keys
    fail "Invalid Add On-#{invalid_add_ons}" if invalid_add_ons.present?

    fail 'Whitelist cannot be setup if Ethereum Address is not selected for kyc form' if has_whitelist_ad_on &&
        kyc_config["kyc_fields"].exclude?(GlobalConstant::ClientKycConfigDetail.ethereum_address_kyc_field)

    fail 'token sale details cannot be blank' if  token_sale_details.blank? || kyc_config.blank?

    if pepo_campaign_data.present?
      fail 'api_key cannot be blank for pepo_campaign' if pepo_campaign_data['api_key'].blank?
      fail 'api_secret cannot be blank for pepo_campaign' if pepo_campaign_data['api_secret'].blank?
    end

    fail 'Invalid Super Admin Email' if super_admins.blank?

    super_admins.each do |super_admin|
      if super_admin['email'].blank? || super_admin['password'].blank? ||
          super_admin['name'].blank? || !Util::CommonValidateAndSanitize.is_valid_email?(super_admin['email'])
        fail 'Invalid Super Admin Email'
      end
    end

    puts "\tValidation passed"

    setup_properties_val = 1 # aml setup is done
    setup_properties_val += 2 if pepo_campaign_data.present?
    setup_properties_val += 4 if has_whitelist_ad_on.present?
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
                           uuid: uuid,
                           api_secret: api_secret_e)
    client_id = client.id

    obj = AdminSessionSetting.new(
        client_id: client.id,
        status: GlobalConstant::AdminSessionSetting.active_status,
        log_sync: true,
        source: GlobalConstant::AdminActivityChangeLogger.script_source
    )

    AdminSessionSetting.admin_types_config.map{|at,_|  obj.send("set_#{at.to_s}") }
    obj.default_setting!
    obj.save!


    puts "\tclient created"


    ClientShard.create!(client_id: client_id, shard_identifier: GlobalConstant::SqlShard.primary_shard_identifier.to_s)

    super_admin_obj = nil
    super_admins.each do |super_admin|
      super_admin_obj = Admin.add_admin(client_id, super_admin['email'],
                                        super_admin['password'], super_admin['name'], true)
    end

    puts "\tsuper admins created"

    ckps_obj = ClientKycPassSetting.new(client_id: client_id, face_match_percent: 100,
                                        approve_type: GlobalConstant::ClientKycPassSetting.manual_approve_type,
                                        status: GlobalConstant::ClientKycPassSetting.active_status,
                                        created_at: Time.now - ClientManagement::UpdateAutoApproveSetting::TIMEFRAME_FOR_SETTING_UPDATE_IN_MINUTES.minutes)

    ClientKycPassSetting.ocr_comparison_fields_config.keys.each do |key|
      ckps_obj.send("set_#{key}")
    end
    ckps_obj.save!

    puts "\tKycPassSetting created"

    if pepo_campaign_data.present?
      r = LocalCipher.new(api_salt_d).encrypt(pepo_campaign_data['api_secret'])
      return r unless r.success?

      pepo_campaign_api_secret_e = r.data[:ciphertext_blob]

      ClientPepoCampaignDetail.create(client_id: client_id, api_key: pepo_campaign_data['api_key'],
                                      api_secret: pepo_campaign_api_secret_e,
                                      status: GlobalConstant::ClientPepoCampaignDetail.active_status)

      puts "\tPepoCampaign setup done"
    end

    start_time = token_sale_details["sale_start_timestamp"] || Time.now.to_i
    end_time = token_sale_details["sale_end_timestamp"] || (start_time + 1.month.to_i)

    ClientTokenSaleDetail.create!(
        client_id: client_id,
        sale_start_timestamp: start_time,
        registration_end_timestamp: token_sale_details["registration_end_timestamp"],
        sale_end_timestamp: end_time,
        token_name: token_sale_details['token_name'],
        token_symbol: token_sale_details['token_symbol'],
        ethereum_deposit_address: nil,
        status: GlobalConstant::ClientTokenSaleDetail.active_status,
        source: GlobalConstant::AdminActivityChangeLogger.script_source
    )

    puts "\tTokenSale setup done"
    ClientKycConfigDetail.add_config(client_id: client_id, kyc_fields: kyc_config["kyc_fields"],
                                     residency_proof_nationalities: kyc_config["residency_proof_nationalities"] || [],
                                     blacklisted_countries: kyc_config["blacklisted_countries"] || [],
                                     extra_kyc_fields: kyc_config['extra_kyc_fields'] || {},
                                     auto_send_kyc_emails: kyc_config['auto_send_kyc_emails']
    )

    puts "\tKycConfig setup done"

    cp = ClientPlan.new(client_id: client_id,
                        kyc_submissions_count: client_plan['kyc_submissions_count'].to_i,
                        status: GlobalConstant::ClientPlan.active_status)

    client_plan['add_ons'].each do |add_on|
      cp.send("set_#{add_on}")
    end
    cp.save!

    puts "\tClientPlan setup done"

    if web_host_data.present?
      ClientWebHostDetail.create!(client_id: client_id, domain: web_host_data["domain"],
                                  status: GlobalConstant::ClientWebHostDetail.active_status)

      ClientManagement::SetupDefaultClientCustomDraft.new(admin_id: super_admin_obj.id,
                                                          client_id: client_id,
                                                          entity_type_and_data_hash: params["entity_type_and_data_hash"]).perform

      puts "\tWebHost setup done"
    end

    # puts "client_id= #{client_id}"
    # puts "uuid= #{uuid}"
  end

end

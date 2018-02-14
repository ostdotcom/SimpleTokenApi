namespace :onetimer do


  # params = {
  #     "client_name" => "secondclient-pepokyc.developmentost.com",
  #     "cynopsis" => {
  #         "domain_name" => GlobalConstant::Cynopsis.domain_name,
  #         "token" => GlobalConstant::Cynopsis.token,
  #         "base_url" => GlobalConstant::Cynopsis.base_url
  #     },
  #     "pepo_campaign" => {
  #         "api_key" => '0455fbd02e9512168211903ff25094d8',
  #         "api_secret" => '4c1b4ec0983ab6b1e37d1c1fc31de5e6'
  #     },
  #     "whitelist" => {
  #         "contract_address" => '0x22A6B1B34Bfe6E95c9180828dd284b171a9515b0',
  #         "whitelister_address" => '0x7316bef49c8149a2fab0d88cab5835949f1d5681'
  #     },
  #     "web_host" => {
  #         "domain" => "pepokyc.developmentost.com"
  #     },
  #     "token_sale_details" => {
  #         "sale_start_timestamp" => 1514811600,
  #         "sale_end_timestamp" => 1519064686,
  #         "ethereum_deposit_address" => "0xEc9859B0B3B4652aD5e264776a79E544b76aman2",
  #     },
  #     "kyc_config" => {
  #         "kyc_fields" => [
  #             "first_name",
  #             "last_name",
  #             "dob_name",
  #             "country",
  #             "ethereum_address",
  #             "document_id",
  #             "nationality",
  #             "document_id_file_path",
  #             "selfie_file_path",
  #             "residence_proof_file_path",
  #             # "stree_address",
  #             # "city",
  #             "state",
  #             # "postal_code"
  #         ],
  #         "residency_proof_nationalities" => [
  #             'CHINESE',
  #             'NEW ZEALANDER',
  #             'AFGHANI',
  #             'BOSNIAN',
  #             'CENTRAL AFRICAN',
  #             'CONGOLESE',
  #             'CUBAN',
  #             'ERITREAN',
  #             'ETHIOPIAN',
  #             'IRANIAN',
  #             'IRAQI',
  #             'LEBANESE',
  #             'LIBYAN',
  #             'NORTH KOREAN',
  #             'SOMALI',
  #             'SOUTH SUDANESE',
  #             'SUDANESE',
  #             'SRI LANKAN',
  #             'SYRIAN',
  #             'TUNISIAN',
  #             'NI-VANUATU',
  #             'YEMENI'
  #         ]
  #
  #     }
  # }

#   system("rake RAILS_ENV=#{Rails.env} onetimer:add_client params='
# {\"client_name\":\"thirdtoken\",\"cynopsis\":{\"domain_name\":\"SIMPLETOKEN\",\"token\":\"11e73a1b-b41f-425d-b10e-36dfcbdab6ed-1234\",\"base_url\":\"https://d1.cynopsis-solutions.com/artemis_simpletoken\"},\"pepo_campaign\":{\"api_key\":\"0455fbd02e9512168211903ff25094d8\",\"api_secret\":\"4c1b4ec0983ab6b1e37d1c1fc31de5e6\"},\"whitelist\":{\"contract_address\":\"0x6AF98e753f79353eb997ADBe6c2E3BF3565b0142\"}}
# '")


# params = params.to_json
# rake RAILS_ENV=development onetimer:add_client params="{\"client_name\":\"simpletoken\",\"cynopsis\":{\"domain_name\":\"bar\",\"token\":\"notmuch\",\"base_url\":\"bar\"},\"pepo_campaign\":{\"api_key\":\"bar\",\"api_secret\":\"notmuch\"}}"

  task :add_client => :environment do

    params = JSON.parse(ENV['params'])
    cynopsis_data = params["cynopsis"]
    pepo_campaign_data = params["pepo_campaign"]
    whitelist_data = params["whitelist"]
    web_host_data = params["web_host"]
    token_sale_details = params["token_sale_details"]
    kyc_config = params["kyc_config"]

    fail 'token cannot be blank for cynopsis' if cynopsis_data['token'].blank? || token_sale_details.blank? || kyc_config.blank?

    if pepo_campaign_data.present?
      fail 'api_key cannot be blank for pepo_campaign' if pepo_campaign_data['api_key'].blank?
      fail 'api_secret cannot be blank for pepo_campaign' if pepo_campaign_data['api_secret'].blank?
    end

    if whitelist_data.present? && (whitelist_data['contract_address'].blank? || whitelist_data['whitelister_address'].blank?)
      fail 'contract_address or  whitelister_address cannot be blank for whitelist_data'
    end

    setup_properties_val = 1
    setup_properties_val += 2 if pepo_campaign_data.present?
    setup_properties_val += 4 if whitelist_data.present?
    setup_properties_val += 8 if web_host_data.present?


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

    client = Client.create(name: params["client_name"], status: GlobalConstant::Client.active_status,
                           setup_properties: setup_properties_val, api_key: SecureRandom.hex, api_salt: api_salt_e,
                           api_secret: api_secret_e)
    client_id = client.id

    r = LocalCipher.new(api_salt_d).encrypt(cynopsis_data['token'])
    return r unless r.success?

    cynopsis_token_e = r.data[:ciphertext_blob]

    ClientCynopsisDetail.create(client_id: client_id, domain_name: cynopsis_data['domain_name'],
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

    ClientWhitelistDetail.create(client_id: client_id, contract_address: whitelist_data['contract_address'],
                                 whitelister_address: whitelist_data['whitelister_address'],
                                 status: GlobalConstant::ClientPepoCampaignDetail.active_status) if whitelist_data.present?

    ClientWebHostDetail.create!(client_id: client_id, domain: web_host_data["domain"],
                                status: GlobalConstant::ClientWebHostDetail.active_status) if web_host_data.present?

    ClientTokenSaleDetail.create!(
        client_id: client_id,
        sale_start_timestamp: token_sale_details['sale_start_timestamp'],
        sale_end_timestamp: token_sale_details['sale_end_timestamp'],
        ethereum_deposit_address: token_sale_details['ethereum_deposit_address'],
        status: GlobalConstant::ClientTokenSaleDetail.active_status
    )

    ClientKycConfigDetail.add_config(kyc_fields: kyc_config["kyc_fields"],
                                     residency_proof_nationalities: kyc_config["residency_proof_nationalities"],
                                     client_id: client_id)

    puts "api-secret: #{client_api_secret_d}"
  end

end

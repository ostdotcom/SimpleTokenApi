namespace :onetimer do


  # params = {
  #     "client_name" => "thirdtoken",
  #     "cynopsis" => {
  #         "domain_name" => GlobalConstant::Cynopsis.domain_name,
  #         "token" => GlobalConstant::Cynopsis.token,
  #         "base_url" =>  GlobalConstant::Cynopsis.base_url
  #     },
  #     "pepo_campaign" => {
  #         "api_key" => GlobalConstant::PepoCampaigns.api_key,
  #         "api_secret" => GlobalConstant::PepoCampaigns.api_secret
  #     },
  #     "whitelist" => {
  #         "contract_address" => '0x6AF98e753f79353eb997ADBe6c2E3BF3565b0142'
  #         "whitelister_address" => '0x6AF98e753f79353eb997ADBe6c2E3BF3565b0142'
  #     }
  # }

#   system("rake RAILS_ENV=#{Rails.env} onetimer:add_client params='
# {\"client_name\":\"thirdtoken\",\"cynopsis\":{\"domain_name\":\"SIMPLETOKEN\",\"token\":\"11e73a1b-b41f-425d-b10e-36dfcbdab6ed-1234\",\"base_url\":\"https://d1.cynopsis-solutions.com/artemis_simpletoken\"},\"pepo_campaign\":{\"api_key\":\"0455fbd02e9512168211903ff25094d8\",\"api_secret\":\"4c1b4ec0983ab6b1e37d1c1fc31de5e6\"},\"whitelist\":{\"contract_address\":\"0x6AF98e753f79353eb997ADBe6c2E3BF3565b0142\"}}
# '")


# params = params.to_json
# rake RAILS_ENV=development onetimer:add_client params="{\"client_name\":\"simpletoken\",\"cynopsis\":{\"domain_name\":\"bar\",\"token\":\"notmuch\",\"base_url\":\"bar\"},\"pepo_campaign\":{\"api_key\":\"bar\",\"api_secret\":\"notmuch\"}}"

  task :add_client => :environment do

    params= JSON.parse(ENV['params'])
    cynopsis_data = params["cynopsis"]
    pepo_campaign_data = params["pepo_campaign"]
    whitelist_data = params["whitelist"]

    fail 'token cannot be blank for cynopsis' if cynopsis_data['token'].blank?

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


    puts "api-secret: #{client_api_secret_d}"
  end

end

namespace :onetimer do


  # params = {
  #     "client_name" => "simpletoken",
  #     "cynopsis" => {
  #         "domain_name" => GlobalConstant::Cynopsis.domain_name,
  #         "token" => GlobalConstant::Cynopsis.token,
  #         "base_url" =>  GlobalConstant::Cynopsis.base_url
  #     },
  #     "pepo_campaign" => {
  #         "api_key" => GlobalConstant::PepoCampaigns.api_key,
  #         "api_secret" => GlobalConstant::PepoCampaigns.api_secret
  #     }
  # }
  #
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

    if whitelist_data.present?
      fail 'contract_address cannot be blank for whitelist_data' if whitelist_data['contract_address'].blank?
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

    r = LocalCipher.new(api_salt_d).encrypt(SecureRandom.hex)
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
                                 status: GlobalConstant::ClientPepoCampaignDetail.active_status) if whitelist_data.present?


    puts "success"
  end

end

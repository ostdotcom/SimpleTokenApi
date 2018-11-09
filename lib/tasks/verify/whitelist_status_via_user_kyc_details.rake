namespace :verify do

  # rake RAILS_ENV=development verify:whitelist_status_via_user_kyc_details client_id=2

  task :whitelist_status_via_user_kyc_details => :environment do

    client_id = ENV['client_id'].to_i
    fail "invalid client id" if client_id <= 0

    contract_addresses = ClientWhitelistDetail.where(client_id: client_id, status: GlobalConstant::ClientWhitelistDetail.active_status).pluck(:contract_address)
    fail "invalid contract_addresses" if contract_addresses.length != 1
    contract_address = contract_addresses[0]

    user_extended_detail_ids = []
    failed_checks = {}

    UserKycDetail.where(client_id: client_id, whitelist_status: GlobalConstant::UserKycDetail.done_whitelist_status).each do |ukd|
      user_extended_detail_ids << ukd.user_extended_detail_id
    end

    UserExtendedDetail.where(id: user_extended_detail_ids).
        select('id, user_id, kyc_salt, ethereum_address').each do |ued|
      kyc_salt_d = Aws::Kms.new('kyc', 'admin').decrypt(ued.kyc_salt).data[:plaintext]

      ethereum_address_d = LocalCipher.new(kyc_salt_d).decrypt(ued.ethereum_address).data[:plaintext]

      r = Request::OpsApi::GetWhitelistStatus.new.perform(contract_address: contract_address, ethereum_address: ethereum_address_d)

      unless r.success?
        failed_checks[ued.user_id] = r
        next
      end

      puts "INVALID WHITELIST status user_id-#{ued.user_id},  phase- #{r.data['phase'].to_i}" if  r.data['phase'].to_i !=  1
    end

    puts 'failed_checks'
    puts failed_checks

  end

end

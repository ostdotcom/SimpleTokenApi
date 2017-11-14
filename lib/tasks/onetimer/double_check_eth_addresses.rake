namespace :onetimer do

  # rake RAILS_ENV=development onetimer:double_check_eth_addresses

  task :double_check_eth_addresses => :environment do


    user_extended_detail_ids = []
    ued_id_phase_map = {}

    failed_checks = {}
    phase_mismatch_entries = []


    UserKycDetail.where(whitelist_status: 2).each do |ukd|
      user_extended_detail_ids << ukd.user_extended_detail_id
      ued_id_phase_map[ukd.user_extended_detail_id] = ukd.token_sale_participation_phase
    end

    UserExtendedDetail.where(id: user_extended_detail_ids).
      select('id, user_id, kyc_salt, estimated_participation_amount').each do |ued|
      kyc_salt_d = Aws::Kms.new('kyc', 'admin').decrypt(ued.kyc_salt).data[:plaintext]

      ethereum_address_d = LocalCipher.new(kyc_salt_d).decrypt(ued.ethereum_address).data[:plaintext]

      r = OpsApi::Request::GetWhitelistStatus.new.perform(ethereum_address: ethereum_address_d)
      unless r.success?
        failed_checks[ued.user_id] = r
        next
      end

      phase_mismatch_entries << ued.user_id if r.data['phase'] != ued_id_phase_map[ued.user_id]

    end

    puts 'failed_checks'
    puts failed_checks

    puts 'phase_mismatch_entries'
    puts phase_mismatch_entries

  end

end

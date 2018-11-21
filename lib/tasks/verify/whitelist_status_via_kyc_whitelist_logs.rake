namespace :verify do

  # rake RAILS_ENV=development verify:whitelist_status_via_kyc_whitelist_logs

  task :whitelist_status_via_kyc_whitelist_logs => :environment do

    # failed_checks = {}
    # phase_mismatch_entries = []
    # processed_addrs = {}
    #
    # KycWhitelistLog.order('id DESC').all.each do |kwl|
    #
    #   ethereum_address = kwl.ethereum_address
    #
    #   next if processed_addrs[ethereum_address].present?
    #
    #   processed_addrs[ethereum_address] = 1
    #
    #   r = Request::OpsApi::GetWhitelistStatus.new.perform(ethereum_address: ethereum_address)
    #   unless r.success?
    #     failed_checks[kwl.id] = r
    #     next
    #   end
    #
    #   phase_mismatch_entries << kwl.id if r.data['phase'] != kwl.phase
    #
    # end
    #
    # puts 'failed_checks'
    # puts failed_checks
    #
    # puts 'phase_mismatch_entries'
    # puts phase_mismatch_entries

  end

end

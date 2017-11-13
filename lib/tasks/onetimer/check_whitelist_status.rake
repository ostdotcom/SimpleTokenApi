namespace :onetimer do

  # rake RAILS_ENV=development onetimer:check_whitelist_status

  task :check_whitelist_status => :environment do

    failed_checks = []
    phase_mismatch_entries = []

    KycWhitelistLog.all.each do |kwl|

      r = OpsApi::Request::GetWhitelistStatus.new.perform(ethereum_address: kwl.ethereum_address)
      failed_checks << kwl.id unless r.success?

      next

      phase_mismatch_entries << kwl.id if r.data['phase'] != kwl.phase

    end

    puts 'failed_checks'
    puts failed_checks

    puts 'phase_mismatch_entries'
    puts phase_mismatch_entries

  end

end

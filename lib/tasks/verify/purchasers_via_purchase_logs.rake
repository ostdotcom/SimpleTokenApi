namespace :verify do

  # rake verify:purchasers_via_purchase_logs RAILS_ENV=development

  task :purchasers_via_purchase_logs => :environment do

    ethereum_addresses = PurchaseLog.all.pluck(:ethereum_address).uniq

    failed_api_calls = []
    mismatches = []

    ethereum_addresses.each do |ethereum_address|
      r = OpsApi::Request::GetBalance.new.perform({ethereum_address: ethereum_address})
      unless r.success?
        failed_api_calls << ethereum_address
        next
      end

      unless r.data['balance'] >= 0
        mismatches << ethereum_address
      end

    end

    puts '----------------------------'
    puts 'API call failed for: \n' + failed_api_calls.inspect
    puts '----------------------------\n\n\n'
    puts 'Balance 0 found for these purchasers: \n' + mismatches.inspect
    puts '----------------------------'

  end

end

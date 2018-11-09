namespace :verify do

  # rake verify:purchase_amount_via_purchase_logs RAILS_ENV=development

  task :purchase_amount_via_purchase_logs => :environment do

    failed_api_calls = []
    mismatches = {}

    records = PurchaseLog.connection.execute(
      'select ethereum_address, sum(st_wei_value) from purchase_logs group by ethereum_address;')

    records.each do |record|

      ethereum_address = record[0]
      st_wei_value = record[1]

      r = Request::OpsApi::GetBalance.new.perform({ethereum_address: ethereum_address})
      unless r.success?
        failed_api_calls << ethereum_address
        next
      end

      if st_wei_value != r.data['balance'].to_i
        mismatches[ethereum_address] = {table_value: st_wei_value, contract_value: r.data['balance'].to_i}
      end

    end

    puts '----------------------------'
    puts 'API call failed for: \n' + failed_api_calls.inspect
    puts '----------------------------\n\n\n'
    puts 'Balance mismatch found for these purchasers: \n' + mismatches.inspect
    puts '----------------------------'

  end

end

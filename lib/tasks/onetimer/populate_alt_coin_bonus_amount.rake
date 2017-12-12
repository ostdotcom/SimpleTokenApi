namespace :onetimer do

  # rake RAILS_ENV=staging onetimer:populate_alt_coin_bonus_amount

  task :populate_alt_coin_bonus_amount => :environment do

    file = File.open("#{Rails.root}/lib/tasks/onetimer/altCoinBonusResults.csv", 'r')

    rows = file.first.split("\r")

    file.close

    alt_coin_bonus_logs = AltCoinBonusLog.all.index_by(&:ethereum_address)

    total_tokens  = {}

    rows.each_with_index do |row, index|
      arr = row.split(",")
      user_eth_address = arr[0]
      alt_token_name = arr[1].to_s
      eth_amount_in_wei = arr[2].to_i
      alt_token_amount_in_wei = arr[3].to_i
      alt_token_contract_address = arr[4]

      puts "#{index} - #{user_eth_address} - #{alt_token_name} - #{eth_amount_in_wei} - #{alt_token_amount_in_wei} - #{alt_token_contract_address}"

      alt_coin_bonus_log = alt_coin_bonus_logs[user_eth_address]

      fail "alt_coin token name or address did not match" if (alt_coin_bonus_log.alt_token_name.downcase != alt_token_name.downcase) ||
          (alt_coin_bonus_log.alt_token_contract_address.downcase != alt_token_contract_address.downcase)

      fail "eth_amount_in_wei did not match" if alt_coin_bonus_log.eth_amount_in_wei != eth_amount_in_wei

      fail "alt_token_amount_in_wei cannot be 0" if alt_token_amount_in_wei.to_i == 0

      alt_coin_bonus_log.alt_token_amount_in_wei = alt_token_amount_in_wei
      alt_coin_bonus_log.save!

      total_tokens[alt_token_name] ||= 0
      total_tokens[alt_token_name] ||= alt_token_amount_in_wei
    end


    puts "\n\nsummary of total_tokens in wei to be distributed\n\n"

    puts ['token_name', 'alt_token_amount_in_wei', 'alt_token_bonus_amount_in_st'].join(',')

    total_tokens.each do |token_name, alt_token_amount_in_wei|
      puts [token_name, alt_token_amount_in_wei, GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(amount_in_wei)].join(',')
    end

  end

end


namespace :onetimer do

  # rake RAILS_ENV=staging onetimer:populate_alt_coin_bonus_amount

  task :populate_alt_coin_bonus_amount => :environment do

    file = File.open("#{Rails.root}/lib/tasks/onetimer/altCoinBonusResults.csv", 'r')

    rows = []

    file.each_line do |line|
      rows << line.strip.split(',')
    end

    file.close

    alt_coin_bonus_logs = AltCoinBonusLog.all.index_by(&:ethereum_address).transform_keys!(&:downcase)

    total_tokens  = {}

    rows.each_with_index do |row, index|
      user_eth_address = row[0].to_s.downcase
      alt_token_contract_address = row[1].to_s.downcase
      ether_bonus_wei_value = row[2].to_i
      alt_token_amount_in_wei = row[3].to_i

      puts "#{index} - #{user_eth_address} - #{alt_token_contract_address} - #{ether_bonus_wei_value} - #{alt_token_amount_in_wei}"

      alt_coin_bonus_log = alt_coin_bonus_logs[user_eth_address]

      fail "alt_coin token name or address did not match" if alt_coin_bonus_log.alt_token_contract_address.downcase != alt_token_contract_address

      fail "ether_bonus_wei_value did not match" if alt_coin_bonus_log.ether_bonus_wei_value != ether_bonus_wei_value

      fail "alt_token_amount_in_wei cannot be 0" if alt_token_amount_in_wei.to_i == 0

      alt_coin_bonus_log.alt_token_amount_in_wei = alt_token_amount_in_wei
      alt_coin_bonus_log.save!

      total_tokens[alt_coin_bonus_log.alt_token_name] ||= {alt_token_amount_in_wei: 0, decimal: alt_coin_bonus_log.number_of_decimal}
      total_tokens[alt_coin_bonus_log.alt_token_name][:alt_token_amount_in_wei] += alt_token_amount_in_wei
    end


    file = File.open("#{Rails.root}/altcoin_purchase_data.csv", 'r')

    purchase_data = {}

    file.each_line do |line|
      data = line.strip.split(',')
      name = data[0]
      purchase_data[name] = data[2]
    end

    file.close


    puts "\n\nsummary of total_tokens in wei to be distributed\n\n"

    puts ['token_name', 'alt_token_amount_in_wei', 'alt_token_amount_in_basic_unit', 'tokens_left_in_wei', 'decimal'].join(',')

    total_tokens.each do |token_name, data|
      alt_token_amount_in_wei = data[:alt_token_amount_in_wei]
      diff =  purchase_data[token_name].to_i - alt_token_amount_in_wei

      if data[:decimal] > 0
        amount_to_transfer_in_basic_unit =  GlobalConstant::ConversionRate.divide_by_power_of_10(alt_token_amount_in_wei, data[:decimal] ).to_f.round(2)
      else
        amount_to_transfer_in_basic_unit = alt_token_amount_in_wei
      end

      puts [token_name, alt_token_amount_in_wei, amount_to_transfer_in_basic_unit, diff, data[:decimal]].join(',')
    end

  end

end
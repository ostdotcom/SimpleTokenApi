namespace :onetimer do

  # rake onetimer:get_st_bonus_detail_report RAILS_ENV=development
  task :get_st_bonus_detail_report => :environment do

    transaction_details = {}
    ether_to_user_mapping = {}

    records = PurchaseLog.connection.execute(
        'select ethereum_address, sum(st_wei_value) as st_wei_val, sum(ether_wei_value) as ether_wei_val from purchase_logs group by ethereum_address;')

    total_st = 0
    records.each do |record|
      ethereum_address = record[0]
      st_wei_val = record[1]
      ether_wei_val = record[2]
      transaction_details[ethereum_address] = ether_wei_val
      ether_to_user_mapping[ethereum_address] = Md5UserExtendedDetail.get_user_id(ethereum_address)
      total_st += st_wei_val
    end

    pre_sale_st_token_in_wei_value = SaleGlobalVariable.pre_sale_data[:pre_sale_st_token_in_wei_value]

    community_bonus = if total_st >= 180000000
                        30
                      elsif total_st >= 120000000
                        25
                      elsif total_st >= 100000000
                        20
                      else
                        0
                      end

    user_ids = ether_to_user_mapping.values
    user_kyc_details = UserKycDetail.where(user_id: user_ids).all.index_by(&:user_id)

    csv_data = []
    csv_data << ['ethereum_address', 'purchase_in_ether_wei', 'purchase_in_ether_basic_unit' 'st_bonus_wei_value', 'st_bonus_value_in_basic_unit', 'pos_bonus', 'community_bonus']

    total_bonus_in_st_wei = 0
    ether_to_user_mapping.each do |ethereum_address, purchase_in_ether_wei|
      user_kyc_detail = user_kyc_details[user_id]
      purchase_in_ether_basic_unit = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(purchase_in_ether_wei)
      total_bonus = 15 + community_bonus + user_kyc_detail.pos_bonus_percentage.to_i

      st_bonus_wei_value = GlobalConstant::ConversionRate.divide_by_power_of_10(purchase_in_ether_wei * total_bonus, 2).to_i
      st_bonus_value_in_basic_unit = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(st_bonus_wei_value)

      data = [
          ethereum_address,
          purchase_in_ether_wei,
          purchase_in_ether_basic_unit,
          st_bonus_wei_value,
          st_bonus_value_in_basic_unit,
          user_kyc_detail.pos_bonus_percentage.to_i,
          community_bonus
      ]
      csv_data << data
      total_bonus_in_st_wei += st_bonus_wei_value
    end

    puts "----------------------\n\n\n\n\n"
    csv_data.each do |element|
      puts element.join(',')
    end
    puts "-----------------------\n\n\n\n\n"

    puts "\n\n\n\t\t\t Total ST Tokens Sold- #{total_st + pre_sale_st_token_in_wei_value}\n\n\n"
    puts "\n\n\n\t\t\t Total ST Bonus In Wei - #{total_bonus_in_st_wei}\n\n"

  end

end

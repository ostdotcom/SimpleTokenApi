namespace :onetimer do

  # CRITICAL - Make sure to verify PurchaseLog has the right values, nothing is missed, nothing is extra.
  #
  # 1. rake verify:purchase_amount_via_purchase_logs RAILS_ENV=development
  # 2. rake verify:purchasers_via_purchase_logs RAILS_ENV=development
  # 3. Sum(purchase_logs.st_wei_value) + sale_global_variables.pre_sales_st = Contract.total_tokens_sold
  # 4. Check if ethereum address to user id mapping is unique
  #
  # ----------
  # Just to verify:
  # 1. Price Adjustment is not going to effect this script, as eth value remains same, only extra ST will be given to users
  # TODO - Use mysql sum query to get the numbers. Total of all ST should match with: Sum(purchase_logs.st_wei_value) + sale_global_variables.pre_sales_st (Manual Verification)
  #
  # rake onetimer:get_altcoin_bonus_detail_report RAILS_ENV=development

  task :get_altcoin_bonus_detail_report => :environment do

    def check_for_duplicate_ethereum_for_purchasers
      eth_addresses = PurchaseLog.pluck(:ethereum_address).uniq
      sha_ethereums = {}

      eth_addresses.each do |eth_address|
        sha_ethereums[Md5UserExtendedDetail.get_hashed_value(eth_address)] = eth_address
      end

      user_mapping = {}

      Md5UserExtendedDetail.where(ethereum_address: sha_ethereums.keys).all.each do |md5_obj|
        ethereum_address = sha_ethereums[md5_obj.ethereum_address]
        user_mapping[ethereum_address] ||= []
        user_mapping[ethereum_address] << md5_obj.user_extended_detail_id
      end

      ued_ids = user_mapping.values.flatten.uniq
      active_user_extended_detail_ids = UserKycDetail.where(user_extended_detail_id: ued_ids).kyc_admin_and_cynopsis_approved.pluck(:user_extended_detail_id)

      user_mapping.each do |ethereum_address, user_extended_detail_ids|
        fail "#{ethereum_address} has no or duplicate active users" if (user_extended_detail_ids & active_user_extended_detail_ids).length != 1
      end
    end

    def flush_and_insert_alt_bonus_details(array_data, alt_token_hash)
      AltCoinBonusLog.delete_all
      current_time = Time.now.to_s(:db)

      array_data.each_slice(100) do |batched_data|
        sql_data = []
        batched_data.each do |rows|
          token_name = rows[1]
          sql_data << "('#{rows[0]}', #{alt_token_hash[token_name][:alt_token_id]}, '#{token_name}',#{rows[2]},#{rows[4]}, '#{current_time}', '#{current_time}')"
        end
        AltCoinBonusLog.bulk_insert(sql_data)
      end
    end

    check_for_duplicate_ethereum_for_purchasers

    transaction_details = {}
    ether_to_user_mapping = {}

    records = PurchaseLog.connection.execute(
        'select ethereum_address, sum(st_wei_value) as st_wei_val, sum(ether_wei_value) as ether_wei_val from purchase_logs group by ethereum_address;')

    total_st_sold = 0
    records.each do |record|
      ethereum_address = record[0]
      st_wei_val = record[1]
      ether_wei_val = record[2]
      transaction_details[ethereum_address] = ether_wei_val
      ether_to_user_mapping[ethereum_address] = Md5UserExtendedDetail.get_user_id(ethereum_address)
      total_st_sold += st_wei_val
    end

    pre_sale_st_token_in_wei_value = SaleGlobalVariable.pre_sale_data[:pre_sale_st_token_in_wei_value]

    user_ids = ether_to_user_mapping.values
    user_kyc_details = UserKycDetail.where(user_id: user_ids).all.index_by(&:user_id)
    alternate_tokens = AlternateToken.all.index_by(&:id)

    summary_data = {}
    csv_data = []

    ether_to_user_mapping.each do |ethereum_address, user_id|
      user_kyc_detail = user_kyc_details[user_id]

      next if user_kyc_detail.alternate_token_id_for_bonus.to_i == 0

      alt_token_id = user_kyc_detail.alternate_token_id_for_bonus.to_i
      alt_token_name = alternate_tokens[alt_token_id].token_name

      purchase_in_ether_wei = transaction_details[ethereum_address]
      purchase_in_rounded_ether = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(purchase_in_ether_wei)

      altcoin_bonus_in_ether_wei = GlobalConstant::ConversionRate.divide_by_power_of_10(purchase_in_ether_wei, 1).to_i
      altcoin_bonus_in_rounded_ether = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(altcoin_bonus_in_ether_wei)

      data = [
          ethereum_address,
          alt_token_name,
          purchase_in_ether_wei,
          purchase_in_rounded_ether,
          altcoin_bonus_in_ether_wei,
          altcoin_bonus_in_rounded_ether,
          user_kyc_detail.pos_bonus_percentage.to_i
      ]
      csv_data << data

      summary_data[alt_token_name] ||= {
          altcoin_name: alt_token_name,
          ether_wei_value: 0,
          altcoin_bonus_wei_value: 0,
          alt_token_id: alt_token_id
      }

      summary_data[alt_token_name][:ether_wei_value] += purchase_in_ether_wei
      summary_data[alt_token_name][:altcoin_bonus_wei_value] += altcoin_bonus_in_ether_wei
    end

    flush_and_insert_alt_bonus_details(csv_data, summary_data)

    puts "----------------------\n\n\n\n\n"

    puts ['ethereum_address', 'altcoin_name', 'purchase_in_ether_wei', 'purchase_in_ether_basic_unit',
          'altcoin_bonus_in_ether_wei', 'altcoin_bonus_in_basic_unit', 'pos_bonus'].join(',')

    csv_data.each do |element|
      puts element.join(',')
    end

    puts "-----------------------\n\n\n\n\n"

    summary_csv_data = []
    summary_csv_data << ['altcoin_name', 'purchase_in_ether_wei', 'purchase_in_ether_basic_unit', 'altcoin_bonus_in_ether_wei', 'altcoin_bonus_in_basic_unit']

    summary_data.each do |altcoin_name, transaction_data|

      purchase_in_ether_wei = transaction_data[:ether_wei_value]
      purchase_in_rounded_ether = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(purchase_in_ether_wei)

      altcoin_bonus_in_ether_wei = transaction_data[:altcoin_bonus_wei_value]
      altcoin_bonus_in_rounded_ether = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(altcoin_bonus_in_ether_wei)

      summary_csv_data << [altcoin_name, purchase_in_ether_wei, purchase_in_rounded_ether, altcoin_bonus_in_ether_wei, altcoin_bonus_in_rounded_ether]
    end

    puts "----------summary------------\n\n\n\n\n"

    summary_csv_data.each do |element|
      puts element.join(',')
    end

    puts "-----------------------\n\n\n\n\n"

    puts "\n\n\n\t\t\t Total ST Tokens Sold- #{total_st_sold + pre_sale_st_token_in_wei_value}\n\n\n"

  end

end

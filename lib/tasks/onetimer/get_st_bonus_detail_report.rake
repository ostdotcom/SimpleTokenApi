namespace :onetimer do

  # CRITICAL - Make sure to verify PurchaseLog has the right values, nothing is missed, nothing is extra.
  #
  # 1. rake verify:purchase_amount_via_purchase_logs RAILS_ENV=development
  # 2. rake verify:purchasers_via_purchase_logs RAILS_ENV=development
  # 3. Sum(purchase_logs.st_wei_value) + sale_global_variables.pre_sales_st = Contract.total_tokens_sold
  # 4. update community_bonus_percent before running the script
  # 5. verify that no users have pos bonus and altcoin bonus
  # 6. verify that all 1st day purchasers have atleast 1 bonus
  # ----------
  #
  # NOTE:: If eth_adjustment_bonus_percent is in decimal.. multiply total percent by 10^n , so that multiplication is for
  # integers and then divide the product by 10^n using the function GlobalConstant::ConversionRate.divide_by_power_of_10
  # choose n such that all total bonus for all row changes to integer
  #
  #
  # rake onetimer:get_st_bonus_detail_report RAILS_ENV=development
  task :get_st_bonus_detail_report => :environment do

    community_bonus_percent = 25
    eth_adjustment_bonus_percent = 15

    pre_sale_st_token_in_wei_value = SaleGlobalVariable.pre_sale_data[:pre_sale_st_token_in_wei_value]

    def flush_and_insert_bonus_details(array_data)
      BonusTokenLog.delete_all
      current_time = Time.now.to_s(:db)

      array_data.each_slice(100) do |batched_data|
        sql_data = []
        batched_data.each do |rows|
          sql_data << "('#{rows[0]}', #{rows[1]},#{rows[2]},#{rows[3]},#{rows[4]}, #{rows[5]}, #{rows[6]}, #{rows[7]}, #{rows[8]}, #{rows[9]}, #{rows[10]}, #{rows[11]}, #{rows[12]}, #{rows[13]}, '#{current_time}', '#{current_time}')"
        end
        BonusTokenLog.bulk_insert(sql_data)
      end

    end

    def validate_pre_sale_purchase_data
      total_pre_sale_tokens_in_st1, total_pre_sale_tokens_in_st2 = 0, 0
      PreSalePurchaseLog.all.each do |pspl|
        fail "invalid data st_base_token- #{pspl.st_base_token}, is_ingested_in_trustee- #{pspl.is_ingested_in_trustee}" if pspl.st_base_token.to_i <= 0 || ['true', 'false'].exclude?(pspl.is_ingested_in_trustee)
        if pspl.is_ingested_in_trustee == 'true'
          fail "invalid data" if pspl.st_bonus_token.to_i <= 0 || pspl.eth_adjustment_bonus_percent.to_i > 0
        else
          fail "invalid data" if pspl.st_bonus_token.to_i != 0
        end

        fail 'eth_adjustment_bonus_percent should be integer' if pspl.eth_adjustment_bonus_percent.present? && (pspl.eth_adjustment_bonus_percent.to_i != pspl.eth_adjustment_bonus_percent)

        if pspl.is_ingested_in_trustee == 'true'
          total_pre_sale_tokens_in_st1 += pspl.st_base_token
        else
          total_pre_sale_tokens_in_st2 += pspl.st_base_token
        end
      end
      fail 'pre_sale_st_base_token addition not equal1' if total_pre_sale_tokens_in_st1 != total_pre_sale_tokens_in_st2
      fail 'pre_sale_st_base_token addition not equal2' if (total_pre_sale_tokens_in_st1 * GlobalConstant::ConversionRate.ether_to_wei_conversion_rate) != pre_sale_st_token_in_wei_value
    end

    validate_pre_sale_purchase_data

    transaction_details = {}
    st_to_user_mapping = {}

    records = PurchaseLog.connection.execute(
        'select ethereum_address, sum(st_wei_value) as st_wei_val from purchase_logs group by ethereum_address;')

    total_st_sold_in_wei_value = 0
    records.each do |record|
      ethereum_address = record[0]
      st_wei_val = record[1]
      transaction_details[ethereum_address] = st_wei_val
      st_to_user_mapping[ethereum_address] = Md5UserExtendedDetail.get_user_id(ethereum_address)
      total_st_sold_in_wei_value += st_wei_val
    end

    user_ids = st_to_user_mapping.values
    user_kyc_details = UserKycDetail.where(user_id: user_ids).all.index_by(&:user_id)

    csv_data = []

    total_sale_bonus_in_st_wei = 0
    st_to_user_mapping.each do |ethereum_address, user_id|
      purchase_in_st_wei = transaction_details[ethereum_address]
      user_kyc_detail = user_kyc_details[user_id]
      purchase_in_st = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(purchase_in_st_wei)
      total_bonus = eth_adjustment_bonus_percent + community_bonus_percent + user_kyc_detail.pos_bonus_percentage.to_i

      total_bonus_in_wei = GlobalConstant::ConversionRate.divide_by_power_of_10(purchase_in_st_wei * total_bonus, 2).to_i
      total_bonus_value_in_st = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(total_bonus_in_wei)

      pos_bonus_in_wei = GlobalConstant::ConversionRate.divide_by_power_of_10(purchase_in_st_wei * user_kyc_detail.pos_bonus_percentage.to_i, 2).to_i
      pos_bonus_in_st = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(pos_bonus_in_wei)

      eth_adjustment_bonus_in_wei = GlobalConstant::ConversionRate.divide_by_power_of_10(purchase_in_st_wei * eth_adjustment_bonus_in_wei, 2).to_i
      eth_adjustment_bonus_in_st = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(eth_adjustment_bonus_in_wei)

      community_bonus_in_wei = GlobalConstant::ConversionRate.divide_by_power_of_10(purchase_in_st_wei * community_bonus_percent, 2).to_i
      community_bonus_in_st = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(community_bonus_in_wei)


      data = [
          ethereum_address,
          purchase_in_st_wei,
          purchase_in_st,
          total_bonus_in_wei,
          total_bonus_value_in_st,
          user_kyc_detail.pos_bonus_percentage.to_i,
          pos_bonus_in_st,
          community_bonus_percent,
          community_bonus_in_st,
          eth_adjustment_bonus_percent,
          eth_adjustment_bonus_in_st,
          GlobalConstant::BonusTokenLog.false_is_pre_sale,
          GlobalConstant::BonusTokenLog.false_is_ingested_in_trustee,
          0
      ]
      csv_data << data
      total_sale_bonus_in_st_wei += total_bonus_in_wei
    end

    total_pre_sale_bonus_in_st_wei = 0
    PreSalePurchaseLog.all.each do |pre_sale_data|

      purchase_in_st = pre_sale_data.st_base_token
      purchase_in_st_wei = (purchase_in_st * GlobalConstant::ConversionRate.ether_to_wei_conversion_rate)
      is_ingested_in_trustee = pre_sale_data.is_ingested_in_trustee == 'true' ? 1 : 0

      if is_ingested_in_trustee == 1
        community_bonus_percent_for_row = 0
        eth_adjustment_bonus_percent_for_row = 0
        community_bonus_in_st = 0
        eth_adjustment_bonus_in_st = 0
      else
        community_bonus_percent_for_row = community_bonus_percent
        eth_adjustment_bonus_percent_for_row = pre_sale_data.eth_adjustment_bonus_percent.to_i
        community_bonus_in_st = GlobalConstant::ConversionRate.divide_by_power_of_10((purchase_in_st * community_bonus_percent_for_row), 2)
        eth_adjustment_bonus_in_st = GlobalConstant::ConversionRate.divide_by_power_of_10((purchase_in_st * eth_adjustment_bonus_percent_for_row), 2)
      end

      total_bonus_percent = eth_adjustment_bonus_percent_for_row + community_bonus_percent_for_row

      total_bonus_in_wei = GlobalConstant::ConversionRate.divide_by_power_of_10(purchase_in_st_wei * total_bonus_percent, 2).to_i +
          (pre_sale_data.st_bonus_token.to_i * GlobalConstant::ConversionRate.ether_to_wei_conversion_rate)

      total_bonus_value_in_st = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(total_bonus_in_wei)

      data = [
          pre_sale_data.ethereum_address,
          purchase_in_st_wei,
          purchase_in_st,
          total_bonus_in_wei,
          total_bonus_value_in_st,
          0,
          0,
          community_bonus_percent_for_row,
          community_bonus_in_st,
          eth_adjustment_bonus_percent_for_row,
          eth_adjustment_bonus_in_st,
          GlobalConstant::BonusTokenLog.true_is_pre_sale,
          is_ingested_in_trustee,
          pre_sale_data.st_bonus_token.to_i
      ]
      csv_data << data
      total_pre_sale_bonus_in_st_wei += total_bonus_in_wei
    end

    flush_and_insert_bonus_details(csv_data)

    puts "----------------------\n\n\n\n\n"

    puts ['ethereum_address', 'purchase_in_st_wei', 'purchase_in_st', 'total_bonus_in_wei',
          'total_bonus_value_in_st', 'pos_bonus_percent', 'pos_bonus_in_st', 'community_bonus_percent', 'community_bonus_in_st',
          'eth_adjustment_bonus_percent', 'eth_adjustment_bonus_in_st', 'is_pre_sale', 'is_ingested_in_trustee', 'pre_sale_bonus_in_st'].join(',')

    csv_data.each do |element|
      puts element.join(',')
    end

    puts "-----------------------\n\n\n\n\n"

    puts "\n\n\n\t\t\t Total ST Tokens Sold- #{total_st_sold_in_wei_value + pre_sale_st_token_in_wei_value}\n\n\n"

    puts "\n\n\n\t\t\t Total Web Token Sale ST Bonus In Wei - #{total_sale_bonus_in_st_wei}\n\n"
    puts "\n\n\n\t\t\t Total Pre Sale ST Bonus In Wei - #{total_pre_sale_bonus_in_st_wei}\n\n"
    puts "\n\n\n\t\t\t Total ST Bonus In Wei - #{total_sale_bonus_in_st_wei + total_pre_sale_bonus_in_st_wei}\n\n"
  end

end

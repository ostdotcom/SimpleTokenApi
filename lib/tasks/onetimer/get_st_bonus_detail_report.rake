namespace :onetimer do

  # CRITICAL - Make sure to verify PurchaseLog has the right values, nothing is missed, nothing is extra.
  #
  # 1. rake verify:purchase_amount_via_purchase_logs RAILS_ENV=development
  # 2. rake verify:purchasers_via_purchase_logs RAILS_ENV=development
  # 3. Sum(purchase_logs.st_wei_value) + sale_global_variables.pre_sales_st = Contract.total_tokens_sold
  #
  # ----------
  #
  # rake onetimer:get_st_bonus_detail_report RAILS_ENV=development
  task :get_st_bonus_detail_report => :environment do

    def flush_and_insert_bonus_details(array_data)
      BonusTokenLog.delete_all
      current_time = Time.now.to_s(:db)

      array_data.each_slice(100) do |batched_data|
        sql_data = []
        batched_data.each do |rows|
          sql_data << "('#{rows[0]}', #{rows[1]},#{rows[3]},#{rows[5]},#{rows[6]}, #{rows[7]}, #{rows[8]}, #{rows[9]}, '#{current_time}', '#{current_time}')"
        end
        BonusTokenLog.bulk_insert(sql_data)
      end

    end

    transaction_details = {}
    st_to_user_mapping = {}
    community_bonus_percent = 25
    eth_fluctuation_bonus = 15

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

    pre_sale_st_token_in_wei_value = SaleGlobalVariable.pre_sale_data[:pre_sale_st_token_in_wei_value]

    user_ids = st_to_user_mapping.values
    user_kyc_details = UserKycDetail.where(user_id: user_ids).all.index_by(&:user_id)

    csv_data = []

    # TODO:
    # 1. Question: Should eth_adjustment_bonus to first added to purchase to calculate other bonuses or not?
    # 2. PreSales comunity bonus handling.
    # 3. Store values in table

    total_sale_bonus_in_st_wei = 0
    st_to_user_mapping.each do |ethereum_address, user_id|
      purchase_in_st_wei = transaction_details[ethereum_address]
      user_kyc_detail = user_kyc_details[user_id]
      purchase_in_st_basic_unit = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(purchase_in_st_wei)
      total_bonus = eth_adjustment_bonus + community_bonus_percent + user_kyc_detail.pos_bonus_percentage.to_i

      st_bonus_wei_value = GlobalConstant::ConversionRate.divide_by_power_of_10(purchase_in_st_wei * total_bonus, 2).to_i
      st_bonus_value_in_basic_unit = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(st_bonus_wei_value)

      data = [
          ethereum_address,
          purchase_in_st_wei,
          purchase_in_st_basic_unit,
          st_bonus_wei_value,
          st_bonus_value_in_basic_unit,
          user_kyc_detail.pos_bonus_percentage.to_i,
          community_bonus_percent,
          eth_adjustment_bonus,
          GlobalConstant::BonusTokenLog.false_is_pre_sale,
          0
      ]
      csv_data << data
      total_sale_bonus_in_st_wei += st_bonus_wei_value
    end

    total_pre_sale_bonus_in_st_wei = 0
    PreSalePurchaseLog.all.each do |pre_sale_data|

      purchase_in_st_wei = pre_sale_data.st_wei_value
      purchase_in_st_basic_unit = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(purchase_in_st_wei)
      total_bonus_percent = pre_sale_data.eth_adjustment_bonus_percent.to_i + community_bonus_percent

      st_bonus_wei_value = GlobalConstant::ConversionRate.divide_by_power_of_10(purchase_in_st_wei * total_bonus_percent, 2).to_i + pre_sale_data.st_bonus_wei_value
      st_bonus_value_in_basic_unit = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(st_bonus_wei_value)


      data = [
          pre_sale_data.ethereum_address,
          purchase_in_st_wei,
          purchase_in_st_basic_unit,
          st_bonus_wei_value,
          st_bonus_value_in_basic_unit,
          0,
          community_bonus_percent,
          pre_sale_data.eth_adjustment_bonus_percent.to_i,
          GlobalConstant::BonusTokenLog.true_is_pre_sale,
          pre_sale_data.st_bonus_wei_value
      ]
      csv_data << data
      total_pre_sale_bonus_in_st_wei += st_bonus_wei_value
    end

    flush_and_insert_bonus_details(csv_data)

    puts "----------------------\n\n\n\n\n"

    puts ['ethereum_address', 'purchase_in_st_wei', 'purchase_in_st_basic_unit' 'st_bonus_wei_value',
          'st_bonus_value_in_basic_unit', 'pos_bonus', 'community_bonus_percent', 'eth_adjustment_bonus', 'is_pre_sale', 'st_pre_sale_bonus_wei_value'].join(',')

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

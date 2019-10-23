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

    records = AltCoinBonusLog.all.to_a

    csv_data = []
    total_ether_spent = 0
    total_alt_token_amount = 0

    records.each do |record|
      ethereum_address = record.ethereum_address
      user_id = Md5UserExtendedDetail.using_shard(shard_identifier: GlobalConstant::SqlShard.primary_shard_identifier)
                    .get_user_id(GlobalConstant::TokenSale.st_token_sale_client_id, ethereum_address)

      user_kyc_detail = UserKycDetail.using_shard(shard_identifier: GlobalConstant::SqlShard.primary_shard_identifier)
                            .where(user_id: user_id).first

      user_extended_detail = UserExtendedDetail.using_shard(shard_identifier: GlobalConstant::SqlShard.primary_shard_identifier)
                                 .where(:id => user_kyc_detail.user_extended_detail_id).first

      ether_spent = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(record.ether_wei_value).to_f
      alt_token_amount = GlobalConstant::ConversionRate.divide_by_power_of_10(record.alt_token_amount_in_wei, record.number_of_decimal).to_f

      data = [
          ethereum_address,
          user_extended_detail.first_name,
          user_extended_detail.last_name,
          record.alt_token_name,
          ether_spent,
          record.ether_wei_value,
          alt_token_amount,
          record.alt_token_amount_in_wei,
          record.number_of_decimal
      ]

      csv_data << data
      total_ether_spent += ether_spent
      total_alt_token_amount += alt_token_amount
    end

    puts "----------------------\n\n\n\n\n"

    puts [
             'ethereum_address',
             'first_name',
             'last_name',
             'alt_token_name',
             'ether_spent',
             'ether_spent_in_wei',
             'total_alt_bonus',
             'total_alt_bonus_in_wei',
             'number_of_decimal'
         ].join(',')


    csv_data.each do |element|
      puts element.join(',')
    end

    puts "-----------------------\n\n\n\n\n"
    puts "--------\n total_ether_spent: #{total_ether_spent}"
    puts "--------\n alt_token_amount: #{total_alt_token_amount}"
  end

end

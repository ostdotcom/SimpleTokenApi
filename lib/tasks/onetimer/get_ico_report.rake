namespace :onetimer do

  task :get_ico_report => :environment do
    Rails.logger.level = Logger::DEBUG

    csv_data = []
    total_ether_spent = 0
    total_ost_purchased = 0
    total_ost_bonus = 0


    records = BonusTokenLog.where(is_pre_sale: 0).all.to_a

    records.each do |record|
      ethereum_address = record.ethereum_address
      user_id = Md5UserExtendedDetail.using_shard(shard_identifier: GlobalConstant::SqlShard.primary_shard_identifier)
                    .get_user_id(GlobalConstant::TokenSale.st_token_sale_client_id, ethereum_address)

      purchase_record = PurchaseLog.select('sum(ether_wei_value) as total_ether_wei_value').where(ethereum_address: ethereum_address).first
      user_kyc_detail = UserKycDetail.using_shard(shard_identifier: GlobalConstant::SqlShard.primary_shard_identifier)
                            .where(user_id: user_id).first

      user_extended_detail = UserExtendedDetail.using_shard(shard_identifier: GlobalConstant::SqlShard.primary_shard_identifier)
                                 .where(:id => user_kyc_detail.user_extended_detail_id).first

      ether_spent = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(purchase_record.total_ether_wei_value).to_f

      data = [
          ethereum_address,
          user_extended_detail.first_name,
          user_extended_detail.last_name,
          ether_spent,
          purchase_record.total_ether_wei_value,
          record.purchase_in_st,
          record.purchase_in_st_wei,
          record.total_bonus_value_in_st,
          record.total_bonus_in_wei,
      ]
      csv_data << data
      total_ether_spent += ether_spent
      total_ost_purchased += record.purchase_in_st
      total_ost_bonus += record.total_bonus_value_in_st
    end

    puts "----------------------\n\n\n\n\n"

    puts [
             'ethereum_address',
             'first_name',
             'last_name',
             'ether_spent',
             'ether_spent_in_wei',
             'ost_purchased',
             'ost_purchased_in_wei',
             'total_ost_bonus',
             'total_ost_bonus_in_wei'
         ].join(',')


    csv_data.each do |element|
      puts element.join(',')
    end

    puts "-----------------------\n\n\n\n\n"
    puts "--------\n total_ether_spent: #{total_ether_spent}"
    puts "--------\n total_ost_purchased: #{total_ost_purchased}"
    puts "--------\n total_ost_bonus: #{total_ost_bonus}"
  end

end

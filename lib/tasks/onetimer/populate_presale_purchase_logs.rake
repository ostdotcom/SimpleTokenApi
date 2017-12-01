
namespace :onetimer do

  # rake RAILS_ENV=staging onetimer:populate_presale_purchase_logs

  task :populate_presale_purchase_logs => :environment do

    file = File.open("pre_sales.csv", "r")

    db_rows = []
    file.each_with_index do (row, index)
      row.gsub("\r","").gsub("\n","")
      arr = row.split(",")
      eth_address = arr[0]
      st_base_token = arr[1]
      st_bonus_token = arr[2]
      eth_price_adjust_percent = arr[3].to_i
      ingested_in_trustee = (arr[4].to_s.gsub("\r","").gsub("\n","").downcase == "true")

      fail "Invalid data Row #{index} ====> Base Token cannot be zero" if st_base_token.to_i <= 0

      fail "Invalid data Row #{index} ====> Eth price adjustment cannot be more than 10" if eth_price_adjust_percent.to_i > 10

      if ingested_in_trustee
        fail "Invalid data Row #{index} ====> Ingested in trustee is true for 0 bonus tokens" if st_bonus_token.to_i <= 0
        fail "Invalid data Row #{index} ====> Ingested in trustee is true so eth adjustment should be 0." if eth_price_adjust_percent.to_i > 0
      end

      if st_bonus_token.to_i == 0
        fail "Invalid data Row #{index} ====> For 0 bonus tokens ingested_in_trustee should be false" if ingested_in_trustee
      end

      current_time = Time.now.to_s(:db)
      db_rows << "(#{eth_address}, #{st_base_token}, #{st_bonus_token}, #{eth_price_adjust_percent}, #{ingested_in_trustee}, '#{current_time}', '#{current_time}')"
    end

    if db_rows.present?
      PreSalePurchaseLog.bulk_insert(db_rows)
    end

    def validate_pre_sale_purchase_data
      total_pre_sale_tokens_in_st1, total_pre_sale_tokens_in_st2 = 0, 0
      PreSalePurchaseLog.all.each do |pspl|
        fail "invalid data #{pspl.id} st_base_token- #{pspl.st_base_token}" if pspl.st_base_token.to_i <= 0
        if pspl.is_ingested_in_trustee
          fail "invalid data #{pspl.id} ingested true" if pspl.st_bonus_token.to_i <= 0 || pspl.eth_adjustment_bonus_percent.to_i > 0
        else
          fail "invalid data #{pspl.id} ingested false" if pspl.st_bonus_token.to_i != 0
        end

        if pspl.is_ingested_in_trustee
          total_pre_sale_tokens_in_st1 += pspl.st_base_token
        else
          total_pre_sale_tokens_in_st2 += pspl.st_base_token
        end
      end
      fail 'pre_sale_st_base_token addition not equal1' if total_pre_sale_tokens_in_st1 != total_pre_sale_tokens_in_st2
      fail 'pre_sale_st_base_token addition not equal2' if (total_pre_sale_tokens_in_st1 * GlobalConstant::ConversionRate.ether_to_wei_conversion_rate).to_i !=
          SaleGlobalVariable.pre_sale_data[:pre_sale_st_token_in_wei_value]
    end

    validate_pre_sale_purchase_data

  end

end

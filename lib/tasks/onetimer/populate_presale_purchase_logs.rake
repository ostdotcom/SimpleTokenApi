
namespace :onetimer do

  # rake RAILS_ENV=staging onetimer:populate_presale_purchase_logs

  task :populate_presale_purchase_logs => :environment do

    file = File.open("#{Rails.root}/lib/tasks/onetimer/bonus-calculations-processing.csv", 'r')

    rows = file.first.split("\r")

    file.close

    db_rows = []
    rows.each_with_index do |row, index|
      arr = row.split(",")
      eth_address = arr[0]
      st_base_token = arr[1]
      st_bonus_token = arr[2]
      discretionary_percent = arr[3].to_i
      ingested_in_trustee = (arr[4].to_s.downcase == "true")

      puts "#{index} - #{eth_address} - #{st_base_token} - #{st_bonus_token} - #{discretionary_percent} - #{ingested_in_trustee}"

      fail "Invalid data Row #{index} ====> Base Token cannot be zero" if st_base_token.to_i <= 0

      fail "Invalid data Row #{index} ====> discretionary_percent cannot be more than 10" if discretionary_percent.to_i > 10

      if ingested_in_trustee
        fail "Invalid data Row #{index} ====> Ingested in trustee is true for 0 bonus tokens" if st_bonus_token.to_i <= 0
        fail "Invalid data Row #{index} ====> Ingested in trustee is true so discretionary_percent should be 0." if discretionary_percent.to_i > 0
      end

      if st_bonus_token.to_i == 0
        fail "Invalid data Row #{index} ====> For 0 bonus tokens ingested_in_trustee should be false" if ingested_in_trustee
      end

      # st_base_token_in_wei = (st_base_token * GlobalConstant::ConversionRate.ether_to_wei_conversion_rate)
      # st_bonus_token_in_wei = (st_bonus_token * GlobalConstant::ConversionRate.ether_to_wei_conversion_rate)
      db_rows << "('#{eth_address}', #{st_base_token}, #{st_bonus_token}, #{discretionary_percent}, #{ingested_in_trustee})"
    end

    if db_rows.present?
      PreSalePurchaseLog.delete_all
      PreSalePurchaseLog.bulk_insert(db_rows)
    end

    def validate_pre_sale_purchase_data
      total_pre_sale_tokens_in_st1, total_pre_sale_tokens_in_st2 = 0, 0
      PreSalePurchaseLog.all.each do |pspl|
        fail "invalid data #{pspl.id} st_base_token- #{pspl.st_base_token}" if pspl.st_base_token.to_i <= 0
        if pspl.is_ingested_in_trustee
          fail "invalid data #{pspl.id} ingested true" if pspl.st_bonus_token.to_i <= 0 || pspl.discretionary_bonus_percent.to_i > 0
        end

        if pspl.st_bonus_token.to_i == 0
          fail "invalid data #{pspl.id} ingested false" if pspl.is_ingested_in_trustee
        end

        if pspl.is_ingested_in_trustee
          total_pre_sale_tokens_in_st1 += pspl.st_base_token
        else
          total_pre_sale_tokens_in_st2 += pspl.st_base_token
        end
      end

      puts "Ingested in trustee total - #{total_pre_sale_tokens_in_st1} && Not ingested total - #{total_pre_sale_tokens_in_st2}"
      fail 'pre_sale_st_base_token addition not equal2' if total_pre_sale_tokens_in_st1 !=
          SaleGlobalVariable.pre_sale_data[:pre_sale_st_token_in_wei_value]
    end

    validate_pre_sale_purchase_data

  end

end

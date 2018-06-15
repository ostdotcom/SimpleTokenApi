namespace :vision_poc do

  # rake vision_poc:compare_document_image_text RAILS_ENV=development

  task :compare_document_image_text => :environment do

    UserKycDetail.select('id, user_id, user_extended_detail_id')
        .where(client_id: GlobalConstant::TokenSale.st_token_sale_client_id)
        .find_in_batches(batch_size: 100) do |batches|

      batches.each do |user_kyc_detail|
        Rails.logger.info "Case Id: #{user_kyc_detail.id}"
        puts "Case Id: #{user_kyc_detail.id}"

        ued = UserExtendedDetail.where(id: user_kyc_detail.user_extended_detail_id).first

        r = Aws::Kms.new('kyc', 'admin').decrypt(ued.kyc_salt)

        kyc_salt_d = r.data[:plaintext]

        local_cipher_obj = LocalCipher.new(kyc_salt_d)

        document_file = nil
        document_file = local_cipher_obj.decrypt(ued.document_id_file_path).data[:plaintext]

        resp = Google::VisionService.new.api_call_detect_text(document_file)
        request_time = resp.data[:request_time]


        puts "Google Vision Request Time: #{resp.data[:request_time]} milliseconds."

        insert_row = {case_id: user_kyc_detail.id, request_time: request_time}

        comparison_columns = {first_name: 0, last_name: 0, birthdate: 0,
                              document_id_number: 0, nationality: 0}


        debug_data = {}

        if resp.success?
          words_array = resp.data[:words_array]
          debug_data = {words_array: words_array, not_match_data: {}}


          if words_array.present?
            comparison_columns.each do |key, _|
              column_name = key.to_sym

              db_value = nil
              if [:first_name, :last_name].include?(column_name)
                db_value = ued[column_name]
              else
                db_value = local_cipher_obj.decrypt(ued[column_name]).data[:plaintext] if ued[column_name].present?
              end

              if db_value.present?
                words_array.each do |word|
                  if column_name == :birthdate
                    db_value = Time.zone.strptime(db_value, "%Y-%m-%d").strftime("%Y-%m-%d")
                    if date_matches?(db_value, word)
                      comparison_columns[column_name] = 100
                    end
                  else
                    if db_value.downcase == word.downcase
                      comparison_columns[column_name] = 100
                    end
                  end
                end
              end

              insert_row["#{key}_match_percent".to_sym] = comparison_columns[column_name]
              debug_data[:not_match_data][column_name] = db_value if comparison_columns[column_name] == 0
            end
          end
        else
          debug_data = resp.data[:debug_data]
        end

        insert_row.merge!({debug_data: debug_data})
        puts insert_row
        VisionCompareText.create!(insert_row)
      end
    end

  end

  def date_matches?(src, des)
    parsed_date = Date.parse(des) rescue nil
    return false if parsed_date.nil?

    src == parsed_date.to_s
  rescue => e
    false
  end

end
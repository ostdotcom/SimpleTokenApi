namespace :rekognition_poc do

  # rake rekognition_poc:compare_document_image_text RAILS_ENV=development

  task :compare_document_image_text => :environment do

    UserKycDetail.select('id, user_id, user_extended_detail_id').where(client_id: GlobalConstant::TokenSale.st_token_sale_client_id,
                        admin_status: GlobalConstant::UserKycDetail.admin_approved_statuses).find_in_batches(batch_size: 100) do |batches|
      batches.each do |user_kyc_detail|
        Rails.logger.info "Case Id: #{user_kyc_detail.id}"
        puts "Case Id: #{user_kyc_detail.id}"

        ued = UserExtendedDetail.where(id: user_kyc_detail.user_extended_detail_id).first

        r = Aws::Kms.new('kyc', 'admin').decrypt(ued.kyc_salt)

        kyc_salt_d = r.data[:plaintext]

        local_cipher_obj = LocalCipher.new(kyc_salt_d)

        document_file = nil
        document_file = local_cipher_obj.decrypt(ued.document_id_file_path).data[:plaintext] if ued.document_id_file_path.present?

        resp = Aws::RekognitionService.new.detect_text(user_kyc_detail.user_id, document_file)

        Rails.logger.info "Rekognition Request Time: #{resp.data[:request_time]} milliseconds."
        puts "Rekognition Request Time: #{resp.data[:request_time]} milliseconds."

        insert_row = {case_id: user_kyc_detail.id, request_time: resp.data[:request_time]}
        debug_data = {response: resp.to_json, not_match_data: {}}
        comparison_columns = {first_name: 0, last_name: 0, birthdate: 0,
                      document_id_number: 0, nationality: 0}
        if resp.success? && resp.data[:document_has_text]
          comparison_columns.each do |key, value|
            column_name = key.to_sym

            db_value = nil
            if [:first_name, :last_name].include?(column_name)
              db_value = ued[column_name]
            else
              db_value = local_cipher_obj.decrypt(ued[column_name]).data[:plaintext] if ued[column_name].present?
            end

            if db_value.present?
              resp.data[:detected_text].each do |x|
                if column_name == :birthdate
                  if date_matches?(db_value, x[:text]) && x[:confidence_percent] > comparison_columns[column_name]
                    comparison_columns[column_name] = x[:confidence_percent]
                  end
                else
                  if db_value.downcase == x[:text].downcase && x[:confidence_percent] > comparison_columns[column_name]
                    comparison_columns[column_name] = x[:confidence_percent]
                  end
                end
              end
            end

            insert_row["#{key}_match_percent".to_sym] = comparison_columns[column_name]
            debug_data[:not_match_data][column_name] = db_value if comparison_columns[column_name] == 0
          end

        end
        Rails.logger.info "Data Comparison Response: #{comparison_columns.inspect}"
        puts "Data Comparison Response: #{comparison_columns.inspect}"
        insert_row.merge!({debug_data: debug_data.to_json})
        RekognitionCompareText.create(insert_row)
      end
    end

  end

  def date_matches?(src, des)
    begin
      return (src.to_date == des.to_date)
    rescue

    end
    return false
  end

end

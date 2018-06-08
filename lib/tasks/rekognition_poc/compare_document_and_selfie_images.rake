namespace :rekognition_poc do

  # rake rekognition_poc:compare_document_and_selfie_images RAILS_ENV=development

  task :compare_document_and_selfie_images => :environment do

    UserKycDetail.select('id, user_id').where(client_id: GlobalConstant::TokenSale.st_token_sale_client_id,
                        admin_status: GlobalConstant::UserKycDetail.admin_approved_statuses).find_in_batches(batch_size: 100) do |batches|
      batches.each do |user_kyc_detail|
        Rails.logger.info "Case Id: #{user_kyc_detail.id}"
        puts "Case Id: #{user_kyc_detail.id}"

        resp = Aws::RekognitionService.new.compare_faces(user_kyc_detail.user_id)

        Rails.logger.info "Rekognition Request Time: #{resp.data[:request_time]} milliseconds."
        puts "Rekognition Request Time: #{resp.data[:request_time]} milliseconds."
        insert_row = {case_id: user_kyc_detail.id, request_time: resp.data[:request_time], debug_data: resp.to_json}
        if resp.success? && resp.data[:face_matches].present?
          insert_row[:face_matches] = resp.data[:face_matches]
          max_similar_percent = 0
          resp.data[:face_matches].each do |x|
            max_similar_percent = x[:similarity_percent] if x[:similarity_percent] > max_similar_percent
          end
          insert_row[:similarity_percentage] = max_similar_percent
        end
        RekognitionCompareFace.create(insert_row)
      end
    end

  end

end

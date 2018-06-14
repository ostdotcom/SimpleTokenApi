namespace :rekognition_poc do

  # rake rekognition_poc:detect_face RAILS_ENV=development

  task :detect_face => :environment do

    UserKycDetail.select('id, user_id').where(client_id: GlobalConstant::TokenSale.st_token_sale_client_id).find_in_batches(batch_size: 100) do |batches|
      batches.each do |user_kyc_detail|
        Rails.logger.info "Case Id: #{user_kyc_detail.id}"
        puts "Case Id: #{user_kyc_detail.id}"

        resp_doc, resp_selfie = Aws::RekognitionService.new.detect_face(user_kyc_detail.user_id)

        insert_row_doc = {
            case_id: user_kyc_detail.id,
            request_time: resp_doc.data[:request_time].to_i,
            debug_data_document: resp_doc.data[:debug_data] || {},
            orientation_document: resp_doc.data[:orientation],
            confidence_document: resp_doc.data[:confidence],
            debug_data_selfie: resp_selfie.data[:debug_data] || {},
            orientation_selfie: resp_selfie.data[:orientation],
            confidence_selfie: resp_selfie.data[:confidence]
        }

        RekognitionDetectFace.create!(insert_row_doc)
      end
    end

  end

end

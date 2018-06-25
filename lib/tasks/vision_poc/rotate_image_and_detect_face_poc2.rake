namespace :vision_poc do

  # rake vision_poc:rotate_image_and_detect_face2 RAILS_ENV=development

  task :rotate_image_and_detect_face2 => :environment do

    bucket = GlobalConstant::Aws::Common.kyc_bucket

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
        selfie_file = local_cipher_obj.decrypt(ued.selfie_file_path).data[:plaintext]

        vision_obj = Google::VisionService.new
        result = vision_obj.validate_image_file_name(document_file)
        next unless result.success?
        downloaded_file_name = document_file.split("/").last

        compare_text_result = VisionCompareText.select('id, orientation').where(case_id: user_kyc_detail.id).first

        insert_in_table = {case_id: user_kyc_detail.id}

        rotation_sequence = rotation_angle.keys
        if compare_text_result.present? and rotation_sequence.include?(compare_text_result.orientation)
          rotation_sequence.delete(compare_text_result.orientation)
          rotation_sequence.unshift(compare_text_result.orientation)
          insert_in_table[:orientation_detected] = compare_text_result.orientation
        end

        original_image_path = "#{Rails.root}/public/#{downloaded_file_name}-doc.jpg"
        Aws::S3Manager.new('kyc', 'admin').get(original_image_path, document_file, bucket)
        temp_image_files = [original_image_path]

        result = detect_face_on_vision(rotation_sequence, original_image_path)
        insert_in_table[:actual_orientation_document_match] = result[:match_orientation]
        temp_image_files << result[:temp_image_files]

        insert_in_table[:document_rotation_iteration] = rotation_sequence.index(result[:match_orientation]).nil? ?
                                                          nil : (rotation_sequence.index(result[:match_orientation]) + 1)
        # Document is present
        puts "Result file"
        if result[:local_file].present?
          resp = vision_obj.validate_image_file_name(selfie_file)
          if resp.success?
            selfie_file_name = selfie_file.split("/").last
            selfie_image_path = "#{Rails.root}/public/#{selfie_file_name}-sel.jpg"
            Aws::S3Manager.new('kyc', 'admin').get(selfie_image_path, document_file, bucket)
            temp_image_files << selfie_image_path
            result1 = detect_face_on_vision(rotation_angle.keys, selfie_image_path)
            insert_in_table[:actual_orientation_selfie_match] = result1[:match_orientation]
            temp_image_files << result1[:temp_image_files]
            insert_in_table[:selfie_rotation_iteration] = rotation_angle.keys.index(result1[:match_orientation]).nil? ?
                                                              nil : (rotation_angle.keys.index(result1[:match_orientation]) + 1)
            if result1[:local_file].present?
              puts "Start with Aws Comparison, Document image path: #{result[:local_file]}, Selfie image path: #{result1[:local_file]}"
              response = Aws::RekognitionService.new.compare_faces(user_kyc_detail.user_id, result[:local_file], result1[:local_file])
              puts "Face Comparison Response: #{response.inspect}"
              if response.success? && response.data[:face_matches].present?
                max_height = 0
                begin
                  response.data[:face_matches].each do |fm|
                    if fm[:face_bounding_box][:bounding_box][:height] >= max_height
                      max_height = fm[:face_bounding_box][:bounding_box][:height]
                      insert_in_table[:small_image_similarity_percent] = (insert_in_table[:big_image_similarity_percent] || 0)
                      insert_in_table[:big_image_similarity_percent] = fm[:similarity_percent]
                    else
                      insert_in_table[:small_image_similarity_percent] = fm[:similarity_percent]
                    end
                  end
                rescue => e
                end
              end
              insert_in_table[:aws_face_comparison_response] = response.to_json
            end
          end
        end


        VisionAwsCompareFace.create(insert_in_table)
        temp_image_files.flatten.each{|file_path| File.delete(file_path)}


      end
    end

  end

  def rotation_angle
    return {
        'ROTATE_0' => 0,
        'ROTATE_90' => 90,
        'ROTATE_270' => 270,
        'ROTATE_180' => 180
    }
  end

  def detect_face_on_vision(rotation_sequence, original_image_path)
    temp_image_files = []
    vision_obj = Google::VisionService.new
    rotation_sequence.each do |x|
      rotated_image_path = ""

      puts "Rotation started, Rotation angle: #{rotation_angle[x]}"
      resp = RmagickImageRotation.new("#{original_image_path}", rotation_angle[x]).perform
      rotated_image_path = resp.data[:rotated_image_path]
      puts "Rotation complete, Rotated image: #{rotated_image_path}"
      # Aws::S3Manager.new('kyc', 'user').store("#{document_file}-#{rotation_angle[x]}", File.open(rotated_image_path), bucket)


      if rotated_image_path.present?
        temp_image_files << rotated_image_path
        begin
          resp = vision_obj.api_call_detect_faces(rotated_image_path)
          puts "Rotated Image Path: #{rotated_image_path}, Rotation angle: #{rotation_angle[x]}, Face Detection Response: #{resp.inspect}"
          if resp[:data][:faces] > 0
            return {local_file: rotated_image_path, match_orientation: x, temp_image_files: temp_image_files}
          end
        rescue => e
          return {match_orientation: e.message, temp_image_files: temp_image_files}
        end
      else
        return {match_orientation: "Image rotation failed", temp_image_files: temp_image_files}
      end

    end
    return {match_orientation: "Vision match not found", temp_image_files: temp_image_files}
  end

end
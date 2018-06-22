namespace :vision_poc do

  # rake vision_poc:rotate_image_and_detect_face RAILS_ENV=development

  task :rotate_image_and_detect_face => :environment do

    rotation_angle = {
        'ROTATE_270' => 270,
        'ROTATE_90' => 90,
        'ROTATE_180' => 180,
        'UNDEFINED' => 360,
        'ROTATE_0' => 0
    }
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

        vision_obj = Google::VisionService.new
        result = vision_obj.validate_image_file_name(document_file)
        next unless result.success?
        downloaded_file_name = document_file.split("/").last

        compare_text_result = VisionCompareText.select('id, orientation').where(case_id: user_kyc_detail.id).first

        rotation_sequence = rotation_angle.keys
        if compare_text_result.present? and rotation_sequence.include?(compare_text_result.orientation)
          rotation_sequence.delete(compare_text_result.orientation)
          rotation_sequence.unshift(compare_text_result.orientation)
        end

        original_image_path = "#{Rails.root}/public/#{downloaded_file_name}.jpg"
        Aws::S3Manager.new('kyc', 'admin').get(original_image_path, document_file, bucket)
        temp_image_files = []

        insert_in_table = {case_id: user_kyc_detail.id, rotation_sequence: rotation_sequence}
        rotation_sequence.each do |x|
          rotated_image_path = ""

          if rotation_angle[x] == 0
            rotated_image_path = original_image_path
          else
            puts "Rotation started, Rotation angle: #{rotation_angle[x]}"
            resp = RmagickImageRotation.new(original_image_path, rotation_angle[x]).perform
            rotated_image_path = resp.data[:rotated_image_path]
            puts "Rotation complete, Rotated image: #{rotated_image_path}"
            # Aws::S3Manager.new('kyc', 'user').store("#{document_file}-#{rotation_angle[x]}", File.open(rotated_image_path), bucket)
          end

          if rotated_image_path.present?
            temp_image_files << rotated_image_path
            resp = vision_obj.api_call_detect_faces(rotated_image_path)
            puts "Rotated Image Path: #{rotated_image_path}, Rotation angle: #{rotation_angle[x]}, Face Detection Response: #{resp.inspect}"
            insert_in_table["rotate_#{rotation_angle[x]}".to_sym] = resp.to_hash
          else
            insert_in_table["rotate_#{rotation_angle[x]}".to_sym] = "Image rotation failed"
          end

        end

        VisionDetectFace.create(insert_in_table)
        temp_image_files.each{|file_path| File.delete(file_path)}

      end
    end

  end

end
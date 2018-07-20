namespace :rekognition_poc do

  # rake rekognition_poc:detect_labels_from_images RAILS_ENV=development

  task :detect_labels_from_images => :environment do
    bucket = GlobalConstant::Aws::Common.kyc_bucket
    S3_DOCUMENT_IMAGE_PATH_REGEX = /\A([A-Z0-9\/]*\/)*i\/[A-Z0-9\/]+\Z/i

    UserKycDetail.select('id, user_id, user_extended_detail_id').where("id > 93").where(client_id: GlobalConstant::TokenSale.st_token_sale_client_id).find_in_batches(batch_size: 100) do |batches|
      batches.each do |user_kyc_detail|
        Rails.logger.info "Case Id: #{user_kyc_detail.id}"
        puts "Case Id: #{user_kyc_detail.id}"

        ued = UserExtendedDetail.where(id: user_kyc_detail.user_extended_detail_id).first

        r = Aws::Kms.new('kyc', 'admin').decrypt(ued.kyc_salt)
        kyc_salt_d = r.data[:plaintext]

        local_cipher_obj = LocalCipher.new(kyc_salt_d)
        doc_s3_path = local_cipher_obj.decrypt(ued.document_id_file_path).data[:plaintext] if ued.document_id_file_path.present?
        selfie_path = local_cipher_obj.decrypt(ued.selfie_file_path).data[:plaintext] if ued.selfie_file_path.present?

        downloaded_doc, downloaded_selfie = nil, nil
        temp_files = []
        insert_in_table = {case_id: user_kyc_detail.id}
        begin
          if doc_s3_path.present?
            puts "Downloading Document"
            raise "Invalid document" if !(doc_s3_path =~ S3_DOCUMENT_IMAGE_PATH_REGEX)
            downloaded_doc = "#{Rails.public_path.to_s}/#{doc_s3_path.split('/').last}-doc.jpg"
            Aws::S3Manager.new('kyc', 'admin').get(downloaded_doc, doc_s3_path, bucket)
            temp_files << downloaded_doc
          end

          vacf = VisionAwsCompareFace.where(case_id: user_kyc_detail.id).first
          doc_angle = vacf.present? ? (rotation_angle[vacf.actual_orientation_document_match.to_s]) : nil
          doc_angle ||= rotation_angle['ROTATE_0']
          insert_in_table[:document_id_orientation] = rotation_angle.invert[doc_angle]
          if downloaded_doc.present?
            resp = RmagickImageRotation.new(downloaded_doc, doc_angle).perform
            rotated_image_path = resp.data[:rotated_image_path]
            temp_files << rotated_image_path
            puts "Calling Detect labels for Document"
            res1 = Aws::RekognitionService.new.detect_labels(rotated_image_path)
            insert_in_table[:document_id_labels] = res1.to_json
          end

          if selfie_path.present?
            puts "Downloading Selfie"
            raise "Invalid selfie" if !(selfie_path =~ S3_DOCUMENT_IMAGE_PATH_REGEX)
            downloaded_selfie = "#{Rails.public_path.to_s}/#{selfie_path.split('/').last}-sel.jpg"
            Aws::S3Manager.new('kyc', 'admin').get(downloaded_selfie, selfie_path, bucket)
            temp_files << downloaded_selfie
          end

          selfie_angle = vacf.present? ? (rotation_angle[vacf.actual_orientation_selfie_match.to_s]) : nil
          selfie_angle ||= rotation_angle['ROTATE_0']
          insert_in_table[:selfie_orientation] = rotation_angle.invert[selfie_angle]
          if downloaded_selfie.present?
            resp = RmagickImageRotation.new(downloaded_selfie, selfie_angle).perform
            rotated_image_path = resp.data[:rotated_image_path]
            temp_files << rotated_image_path
            puts "Calling Detect labels for Selfie"
            res1 = Aws::RekognitionService.new.detect_labels(rotated_image_path)
            insert_in_table[:selfie_labels] = res1.to_json
          end

        rescue => e
          ApplicationMailer.notify(
              to: GlobalConstant::Email.default_to,
              body: e.backtrace,
              data: insert_in_table,
              subject: "Exception::Something went wrong while Detecting label."
          ).deliver
        ensure
          AwsDetectLabel.create!(insert_in_table)
          temp_files.each{|file_path| File.delete(file_path)}
          puts "----------- Case #{user_kyc_detail.id} Processed ------"
        end
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

end

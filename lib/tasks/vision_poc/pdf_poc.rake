namespace :vision_poc do

  # rake vision_poc:pdf_poc RAILS_ENV=development

  task :pdf_poc => :environment do

    bucket = GlobalConstant::Aws::Common.kyc_bucket

    VisionCompareText.where("debug_data LIKE ?", "%invalid_file_type%").all.each do |vct|
      user_kyc_detail = UserKycDetail.where(id: vct.case_id).first
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
      next if !result.success? && result.error != "pdf_file"
      downloaded_file_name = document_file.split("/").last

      insert_in_table = {case_id: user_kyc_detail.id}

      download_pdf = "#{Rails.root}/public/#{downloaded_file_name}"
      Aws::S3Manager.new('kyc', 'admin').get(download_pdf, document_file, bucket)
      r = ImageProcessing::PdfToImage.new("#{Rails.root}/public", download_pdf).perform
      temp_image_files = [download_pdf]
      unless r.success?
        temp_image_files.flatten.each{|file_path| File.delete(file_path)}
        next
      end
      original_image_path = r.data[:image_path]
      temp_image_files << original_image_path

      orientation = detect_text(original_image_path, user_kyc_detail, local_cipher_obj, ued, vct)
      rotation_sequence = rotation_angle.keys
      if orientation.present? and rotation_sequence.include?(orientation)
        rotation_sequence.delete(orientation)
        rotation_sequence.unshift(orientation)
        insert_in_table[:orientation_detected] = orientation
      end
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
          Aws::S3Manager.new('kyc', 'admin').get(selfie_image_path, selfie_file, bucket)
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

      VisionAwsCompareFace.create!(insert_in_table)
      temp_image_files.flatten.each{|file_path| File.delete(file_path)}

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

  def detect_face_on_vision(rotation_sequence, image_path)
    temp_image_files = []
    vision_obj = Google::VisionService.new
    rotation_sequence.each do |x|
      rotated_image_path = ""

      puts "Rotation started, Rotation angle: #{rotation_angle[x]}"
      resp = RmagickImageRotation.new(image_path, rotation_angle[x]).perform
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

  def detect_text(document_file, user_kyc_detail, local_cipher_obj, ued, vct)
    resp = Google::VisionService.new.api_call_detect_text(document_file)
    request_time = resp.data[:request_time]
    puts "Google Vision Request Time: #{resp.data[:request_time]} milliseconds."

    insert_row = {case_id: user_kyc_detail.id, request_time: request_time || 0}

    comparison_columns = {first_name: 0, last_name: 0, birthdate: 0,
                          document_id_number: 0, nationality: 0}


    debug_data = {}
    date_of_birth = nil
    if resp.success?
      words_array = resp.data[:words_array]
      debug_data = {words_array: words_array, not_match_data: {}}

      words_hash = construct_lookup_data(words_array)
      all_dates = get_dates(words_array)


      if words_hash.present?
        comparison_columns.each do |key, _|
          column_name = key.to_sym

          db_value = nil
          if [:first_name, :last_name].include?(column_name)
            db_value = ued[column_name]
          else
            db_value = local_cipher_obj.decrypt(ued[column_name]).data[:plaintext] if ued[column_name].present?
          end

          if column_name != :birthdate
            comparison_columns[column_name] = 100 if words_hash[db_value.downcase] == 1
          else
            date_of_birth = Date.parse(db_value, "%Y-%m-%d")
            comparison_columns[column_name] = 100 if all_dates.include?(date_of_birth)
          end

          insert_row["#{key}_match_percent".to_sym] = comparison_columns[column_name]
          debug_data[:not_match_data][column_name] = db_value if comparison_columns[column_name] == 0
        end
      end
    else
      debug_data = resp.data[:debug_data]
    end

    insert_row.merge!({debug_data: debug_data, date_of_birth: date_of_birth, orientation: resp.data[:orientation]})
    puts insert_row
    vct.update_columns(insert_row)
    resp.data[:orientation]
  end

  def construct_lookup_data(paragraph)
    words_hash = {}
    paragraph.split(%r{[\s\n]}).each do |word|
      next if word.blank?
      words_hash[word.downcase] = 1
    end
    words_hash
  end

  def get_dates(paragraph)
    delimeters = '\/\-\. '
    date_regex = /\d{1,4}[#{delimeters}]\d{1,2}[#{delimeters}]\d{2,4}/
    dates = []
    paragraph.split("\n").each do |line|
      next if line.blank?
      date_str_array = line.scan(date_regex)
      date_str_array.each do |date_str|
        dates += get_valid_dates(date_str)
      end
    end
    dates.uniq
  end

  def date_delimeters
    ['/', '-', '.']
  end

  def all_date_formats
    @all_date_formats ||= begin
      formats = []
      date_delimeters.each do |delimeter|
        formats += ["%y#{delimeter}%m#{delimeter}%d", "%d#{delimeter}%m#{delimeter}%y", "%m#{delimeter}%d#{delimeter}%y"]
      end
      formats
    end
  end

  def get_valid_dates(date_str)
    date_objects = []
    all_date_formats.each do |format|
      date = Date.parse(date_str, format) rescue nil
      date_objects << date if date.present?
    end
    date_objects
  end

end
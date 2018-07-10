module Crons

  class ProcessUserSubmittedImages

    include Util::ResultHelper

    # Initialize
    #
    # * Author: Pankaj
    # * Date: 02/07/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def initialize(params)
      @user_kyc_comparison_detail = nil
      @decrypted_user_data = {}
      @zero_rotated_document = nil
      @new_doc_s3_file_name = nil
      @new_selfie_s3_file_name = nil
    end

    # Perform
    #
    # * Author: Pankaj
    # * Date: 02/07/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      fetch_unprocessed_user_kyc_record

      puts @user_kyc_comparison_detail

      return success if @user_kyc_comparison_detail.nil?

      r = fetch_and_decrypt_user_data
      return r unless r.success?

      process_document_id_image

      process_selfie_image

      make_face_comparisons

      if @user_kyc_comparison_detail.image_processing_status = GlobalConstant::ImageProcessing.unprocessed_image_process_status
        update_user_comparison_record(GlobalConstant::ImageProcessing.processed_image_process_status)
      end

      # Delete file directory once complete process is done
      FileUtils.rm_rf(file_directory)

      success

    end

    private

    # Fetch records on which image processing is not yet performed
    #
    # * Author: Pankaj
    # * Date: 02/07/2018
    # * Reviewed By:
    #
    # @sets @user_kyc_comparison_detail
    #
    def fetch_unprocessed_user_kyc_record
      lock_id = Time.now.to_i
      UserKycComparisonDetail.connection.execute("update user_kyc_comparison_details set lock_id=#{lock_id}
          where lock_id IS NULL AND
          image_processing_status = #{UserKycComparisonDetail.image_processing_statuses[GlobalConstant::ImageProcessing.unprocessed_image_process_status]}
          LIMIT 1")
      @user_kyc_comparison_detail = UserKycComparisonDetail.where(lock_id: lock_id).last
    end

    # Fetch user extended details and decrypt user data for further processing
    #
    # * Author: Pankaj
    # * Date: 02/07/2018
    # * Reviewed By:
    #
    # @sets @decrypted_user_data
    #
    # @return [Result::Base]
    #
    def fetch_and_decrypt_user_data
      user_extended_detail = UserExtendedDetail.where(id: @user_kyc_comparison_detail.user_extended_detail_id).first

      r = Aws::Kms.new('kyc', 'admin').decrypt(user_extended_detail.kyc_salt)

      kyc_salt_d = r.data[:plaintext]

      local_cipher_obj = LocalCipher.new(kyc_salt_d)

      @user_kyc_comparison_detail.has_residence_proof = user_extended_detail.residence_proof_file_path.present?.to_i
      @decrypted_user_data[:document_file] = local_cipher_obj.decrypt(user_extended_detail.document_id_file_path).data[:plaintext]
      r = validate_image_file_name(@decrypted_user_data[:document_file])
      unless r.success?
        update_user_comparison_record(GlobalConstant::ImageProcessing.failed_invalid_document_file)
        return r
      end

      @decrypted_user_data[:selfie_file] = local_cipher_obj.decrypt(user_extended_detail.selfie_file_path).data[:plaintext]
      @decrypted_user_data[:first_name] = local_cipher_obj.decrypt(user_extended_detail.first_name).data[:plaintext]
      @decrypted_user_data[:last_name] = local_cipher_obj.decrypt(user_extended_detail.last_name).data[:plaintext]
      @decrypted_user_data[:birthdate] = local_cipher_obj.decrypt(user_extended_detail.birthdate).data[:plaintext]
      @decrypted_user_data[:document_id] = local_cipher_obj.decrypt(user_extended_detail.document_id_number).data[:plaintext]
      @decrypted_user_data[:nationality] = local_cipher_obj.decrypt(user_extended_detail.nationality).data[:plaintext]

      success
    end

    # Validate image file names before processing
    #
    # * Author: Pankaj
    # * Date: 02/07/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_image_file_name(document_file)

      if !(document_file =~ GlobalConstant::UserKycDetail.s3_document_path_regex)
        return error_with_data("invalid_file", "invalid_file", "invalid_file", nil, {})
      end

      if !(document_file =~ GlobalConstant::UserKycDetail.s3_document_image_path_regex)
        return error_with_data("invalid_type", "invalid_type", "invalid_type", nil, {})
      end

      success
    end

    # Update user comparison record status
    #
    # * Author: Pankaj
    # * Date: 02/07/2018
    # * Reviewed By:
    #
    def update_user_comparison_record(image_processing_status)
      @user_kyc_comparison_detail.image_processing_status = image_processing_status
      @user_kyc_comparison_detail.save!
    end

    # Process document id image
    #
    # * Author: Pankaj
    # * Date: 02/07/2018
    # * Reviewed By:
    #
    def process_document_id_image
      document_path = download_image(@decrypted_user_data[:document_file])

      # Rotate image at 0 degree angle to remove its metadata
      # TODO: Find image dimensions from imageMagick
      resp = RmagickImageRotation.new(file_directory, document_path, GlobalConstant::ImageProcessing.rotation_angle_0).perform
      @zero_rotated_document = resp.data[:rotated_image_path]

      # Make a google vision call for detect text
      puts "Vision detect text started"
      r = Google::VisionService.new.detect_text(@zero_rotated_document)
      add_image_process_log(GlobalConstant::ImageProcessing.google_vision_detect_text,
                            {rotation_angle: GlobalConstant::ImageProcessing.rotation_angle_0}, r.to_json)

      # Detect text failed so no more vision calls would happen
      unless r.success?
        update_user_comparison_record(GlobalConstant::ImageProcessing.failed_vision_detect_text)
        return r
      end

      ocr_result = make_ocr_comparisons(r.data).data

      # Make vision call to detect face in document image
      rotation_sequence = GlobalConstant::ImageProcessing.rotation_sequence
      if ocr_result[:rotation_angle].present?
        rotation_sequence.delete(ocr_result[:rotation_angle])
        rotation_sequence.unshift(ocr_result[:rotation_angle])
      end

      resp = rotate_image_and_detect_faces('document', rotation_sequence, document_path)
      correct_oriented_doc = resp.data[:image_path]
      @user_kyc_comparison_detail.document_dimensions = {rotate_angle: resp.data[:rotate_angle]}
      @user_kyc_comparison_detail.save!

      @new_doc_s3_file_name = upload_image(@decrypted_user_data[:document_file],
                                           resp.data[:rotate_angle], correct_oriented_doc)

      success
    end

    # Process selfie image
    #
    # * Author: Pankaj
    # * Date: 02/07/2018
    # * Reviewed By:
    #
    def process_selfie_image
      r = validate_image_file_name(@decrypted_user_data[:selfie_file])
      unless r.success?
        update_user_comparison_record(GlobalConstant::ImageProcessing.failed_invalid_selfie_file)
        return r
      end

      selfie_path = download_image(@decrypted_user_data[:selfie_file])

      # Rotate images and make vision detect face calls
      resp = rotate_image_and_detect_faces('selfie', GlobalConstant::ImageProcessing.rotation_sequence, selfie_path)
      correct_oriented_selfie = resp.data[:image_path]
      @user_kyc_comparison_detail.selfie_dimensions = {rotate_angle: resp.data[:rotate_angle]}
      @user_kyc_comparison_detail.save!

      @new_selfie_s3_file_name = upload_image(@decrypted_user_data[:selfie_file],
                                              resp.data[:rotate_angle], correct_oriented_selfie)

      success
    end

    # Make OCR comparisons on response from third party services
    #
    # * Author: Pankaj
    # * Date: 04/07/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def make_ocr_comparisons(ocr_response)
      rotation_angle = nil
      compare_params = {
          paragraph: ocr_response[:paragraph],
          dimensions: ocr_response[:word_dimensions],
          document_details: @decrypted_user_data
      }

      begin
        r = Ocr::CompareDocument.new(compare_params).perform
        rotation_angle = r.data[:rotation_angle]
        puts r.to_json
        if r.success? && r.data[:comparison_percent].present?
          r.data[:comparison_percent].each do |column, value|
            @user_kyc_comparison_detail["#{column.to_s}_match_percent".to_sym] = value
          end
          @user_kyc_comparison_detail.save!
        end
      rescue => e
        # TODO: notify devs
      end

      success_with_data({rotation_angle: rotation_angle})
    end

    # Rotate image and detect faces using google vision
    #
    # * Author: Pankaj
    # * Date: 04/07/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def rotate_image_and_detect_faces(image_type, rotation_sequence, original_file)
      zero_rotated_image = nil
      rotation_sequence.each do |rotate_angle|
        rotated_image = nil
        # Don't perform rotation once again for 0 angle, has already been done
        if image_type == 'document' && rotate_angle == GlobalConstant::ImageProcessing.rotation_angle_0
          rotated_image = @zero_rotated_document
        else
          puts "#{rotate_angle} - Image Rotation started"
          resp = RmagickImageRotation.new(file_directory, original_file, rotate_angle).perform
          rotated_image = resp.data[:rotated_image_path]
        end
        # Set zero rotated image to send if in case face is not detected in any of the images
        zero_rotated_image = rotated_image if rotate_angle == GlobalConstant::ImageProcessing.rotation_angle_0

        # Call Vision detect face
        if rotated_image.present?
          puts "#{rotate_angle} - Vision detect face started"
          r = Google::VisionService.new.detect_faces(rotated_image)
          add_image_process_log(GlobalConstant::ImageProcessing.google_vision_detect_face,
                                {rotation_angle: rotate_angle, image_type: image_type}, r.to_json)
          # If face is detected then stop further calls
          return success_with_data({image_path: rotated_image, rotate_angle: rotate_angle}) if r.data[:faces].present? and r.data[:faces].length > 0
        end
        #TODO: Question do we need image rotation failed case to log as failed image processing status
      end

      # If face is not detected throughout assume zero rotated image as correct
      return success_with_data({image_path: zero_rotated_image, rotate_angle: GlobalConstant::ImageProcessing.rotation_angle_0})
    end

    # Download images from s3
    #
    # * Author: Pankaj
    # * Date: 02/07/2018
    # * Reviewed By:
    #
    # @return String - Downloaded image path
    #
    def download_image(file_name)
      puts "#{file_name} - Image downloading started"
      downloaded_file_name = file_name.split("/").last
      image_path = "#{file_directory}/#{downloaded_file_name}.jpg"

      Aws::S3Manager.new('kyc', 'admin').get(image_path, file_name, GlobalConstant::Aws::Common.kyc_bucket)

      image_path
    end

    # Upload images to s3
    #
    # * Author: Pankaj
    # * Date: 06/07/2018
    # * Reviewed By:
    #
    # @return String - S3 file name
    #
    def upload_image(file_name, rotation_angle, image_path)
      s3_file_name =  "#{file_name}-#{rotation_angle}"
      puts "#{s3_file_name} - Image uploading started"

      Aws::S3Manager.new('kyc', 'user').
          store(s3_file_name, File.open(image_path), GlobalConstant::Aws::Common.kyc_bucket)

      s3_file_name
    end

    # File Directory
    #
    # * Author: Pankaj
    # * Date: 02/07/2018
    # * Reviewed By:
    #
    # @return String - File directory
    #
    def file_directory
      # Make directory if not exisits
      if @dir.nil?
        d = Rails.public_path.to_s + '/' + "#{@user_kyc_comparison_detail.id}"
        Dir.mkdir(d)
        @dir = d
      end
      @dir
    end

    # Make an entry in image process log
    #
    # * Author: Pankaj
    # * Date: 02/07/2018
    # * Reviewed By:
    #
    def add_image_process_log(service, input, debug_data)
      # TODO: Encrypt debug data with local cipher
      ImageProcessingLog.create!(user_kyc_comparison_detail_id: @user_kyc_comparison_detail.id,
                                 service_used: service,
                                 input_params: input,
                                 debug_data: debug_data)
    end

    # Do face comparison between selfie and document images
    #
    # * Author: Pankaj
    # * Date: 05/07/2018
    # * Reviewed By:
    #
    def make_face_comparisons
      return if @new_doc_s3_file_name.nil? || @new_selfie_s3_file_name.nil?
      puts "AWS compare faces started"

      resp = Aws::RekognitionService.new.compare_faces(@new_doc_s3_file_name, @new_selfie_s3_file_name)

      # If face comparison response has unmatched faces then mark it as failed
      if resp.data.present? && resp.data[:unmatched_faces].present?
        update_user_comparison_record(GlobalConstant::ImageProcessing.failed_unmatched_faces)
      elsif resp.success?
        # Check for bigger face and smaller face percentages
        max_height = 0
        resp.data[:face_matches].present? && resp.data[:face_matches].each do |fm|
          if fm[:face_bounding_box][:bounding_box][:height] >= max_height
            max_height = fm[:face_bounding_box][:bounding_box][:height]
            @user_kyc_comparison_detail.small_face_match_percent = @user_kyc_comparison_detail.big_face_match_percent
            @user_kyc_comparison_detail.big_face_match_percent = fm[:similarity_percent]
          else
            @user_kyc_comparison_detail.small_face_match_percent = fm[:similarity_percent]
          end
        end
        @user_kyc_comparison_detail.save!
      else
        update_user_comparison_record(GlobalConstant::ImageProcessing.failed_aws_compare_faces)
      end

      add_image_process_log(GlobalConstant::ImageProcessing.aws_rekognition_compare_face,
                            {document: @new_doc_s3_file_name, selfie: @new_selfie_s3_file_name}, resp.to_json)

      success
    end

  end

end

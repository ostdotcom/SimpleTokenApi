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
      @shard_identifier = nil
      @cron_identifier = params[:cron_identifier].to_s
      @shard_identifiers = params[:shard_identifiers].present? || GlobalConstant::Shard.shards_to_process_for_crons
      @user_kyc_comparison_detail = nil
      @decrypted_user_data = {}
      @zero_rotated_documents = {}
      @new_doc_s3_file_name = nil
      @new_selfie_s3_file_name = nil
      @ocr_unmatched = ClientKycPassSetting::ocr_comparison_fields_config.keys
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

      @shard_identifiers.each do |shard_identifier|

        @shard_identifier = shard_identifier
        fetch_unprocessed_user_kyc_record

        continue if @user_kyc_comparison_detail.nil?

        begin
          r = fetch_and_decrypt_user_data
          raise r.to_json.to_json unless r.success?

          r = process_document_id_image
          raise r.to_json.to_json unless r.success?

          process_selfie_image

          make_face_comparisons

          update_user_comparison_record(nil, GlobalConstant::ImageProcessing.processed_image_process_status)

          trigger_auto_approval

          success
        rescue => e
          update_user_comparison_record(GlobalConstant::KycAutoApproveFailedReason.unexpected_reason, GlobalConstant::ImageProcessing.failed_image_process_status)

          ApplicationMailer.notify(
              body: e.backtrace,
              data: {user_kyc_comparison_detail: @user_kyc_comparison_detail.id, message: e.message},
              subject: "Exception in ProcessUserSubmittedImages"
          ).deliver

        ensure
          # Delete file directory once complete process is done
          Util::FileSystem.delete_directory(file_directory)
        end

        return if GlobalConstant::SignalHandling.sigint_received?

      end

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
      UserKycComparisonDetail.using_shard(shard_identifier: @shard_identifier).where('lock_id IS NULL').
          where(image_processing_status: GlobalConstant::ImageProcessing.unprocessed_image_process_status).
          order({id: :desc}).limit(1).update_all(lock_id: table_lock_id)

      @user_kyc_comparison_detail = UserKycComparisonDetail.using_shard(shard_identifier: @shard_identifier).
          where(lock_id: table_lock_id).last
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
      user_extended_detail = UserExtendedDetail.using_shard(shard_identifier: @shard_identifier).
          where(id: @user_kyc_comparison_detail.user_extended_detail_id).first

      r = Aws::Kms.new('kyc', 'admin').decrypt(user_extended_detail.kyc_salt)
      kyc_salt_d = r.data[:plaintext]
      get_local_cipher_object(kyc_salt_d)

      @decrypted_user_data[:document_id_file_path] = get_local_cipher_object.decrypt(user_extended_detail.document_id_file_path).data[:plaintext]

      @decrypted_user_data[:selfie_file_path] = get_local_cipher_object.decrypt(user_extended_detail.selfie_file_path).data[:plaintext]

      ClientKycPassSetting::ocr_comparison_fields_config.keys.each do |field_name|
        if GlobalConstant::ClientKycConfigDetail.unencrypted_fields.include?(field_name.to_s)
          @decrypted_user_data[field_name.to_sym] = user_extended_detail[field_name]
        else
          @decrypted_user_data[field_name.to_sym] = get_local_cipher_object.decrypt(user_extended_detail[field_name]).data[:plaintext]
        end
      end

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

      if !(document_file =~ GlobalConstant::UserKycDetail.s3_document_image_path_regex)
        return error_with_data("cr_pusi_2", "invalid_type", "invalid_type", nil, {})
      end

      success
    end

    # Update user comparison record status
    #
    # * Author: Pankaj
    # * Date: 02/07/2018
    # * Reviewed By:
    #
    def update_user_comparison_record(failed_reason, image_processing_status)
      @user_kyc_comparison_detail.auto_approve_failed_reasons = @user_kyc_comparison_detail.send("set_#{failed_reason}") if failed_reason.present?
      @user_kyc_comparison_detail.image_processing_status = image_processing_status if image_processing_status.present?
      @user_kyc_comparison_detail.save!
    end

    # Process document id image
    #
    # * Author: Pankaj
    # * Date: 02/07/2018
    # * Reviewed By:
    #
    def process_document_id_image
      doc_type = "document"
      resp = perform_validation_and_basic_operation_on_files(@decrypted_user_data[:document_id_file_path], doc_type)
      return resp unless resp.success?

      original_downloaded_document_image = resp.data[:original_downloaded_image]
      converted_from_pdf = resp.data[:converted_from_pdf]

      zero_rotated_document = @zero_rotated_documents[doc_type]
      # Make a google vision call for detect text
      puts "Vision detect text started"
      r = Google::VisionService.new.detect_text(zero_rotated_document[:rotated_image_path])
      log_resp = r.success? ? {paragraph: r.data[:paragraph], request_time: r.data[:request_time]} : r.to_json
      add_image_process_log(GlobalConstant::ImageProcessing.google_vision_detect_text,
                            {rotation_angle: GlobalConstant::ImageProcessing.rotation_angle_0}, log_resp)

      # Detect text failed so no more vision calls would happen for document
      correct_oriented_doc = zero_rotated_document

      if r.success?
        ocr_result = make_ocr_comparisons(r.data, @decrypted_user_data).data

        # Make vision call to detect face in document image
        rotation_sequence = GlobalConstant::ImageProcessing.rotation_sequence
        if ocr_result[:rotation_angle].present?
          rotation_sequence.delete(ocr_result[:rotation_angle])
          rotation_sequence.unshift(ocr_result[:rotation_angle])
        end

        resp = rotate_image_and_detect_faces(doc_type, rotation_sequence, original_downloaded_document_image)
        correct_oriented_doc = resp.data
      end

      if correct_oriented_doc.present?
        @new_doc_s3_file_name = upload_image(@decrypted_user_data[:document_id_file_path],
                                             correct_oriented_doc[:rotation_angle], correct_oriented_doc[:rotated_image_path])

        document_dimensions = {
            width: correct_oriented_doc[:width],
            height: correct_oriented_doc[:height]
        }
        converted_from_pdf ? document_dimensions.merge!(pdf_rotation_angle: correct_oriented_doc[:rotation_angle]) :
            document_dimensions.merge!(rotation_angle: correct_oriented_doc[:rotation_angle])

        @user_kyc_comparison_detail.document_dimensions = document_dimensions
        @user_kyc_comparison_detail.save!
      end

      make_aws_text_detect_call

      success
    end

    # Process selfie image
    #
    # * Author: Pankaj
    # * Date: 02/07/2018
    # * Reviewed By:
    #
    def process_selfie_image
      doc_type = "selfie"
      res = perform_validation_and_basic_operation_on_files(@decrypted_user_data[:selfie_file_path], doc_type)
      return res unless res.success?

      selfie_path = res.data[:original_downloaded_image]
      converted_from_pdf = res.data[:converted_from_pdf]

      # Rotate images and make vision detect face calls
      resp = rotate_image_and_detect_faces(doc_type, GlobalConstant::ImageProcessing.rotation_sequence, selfie_path)
      # If rotation and detect face fails then go with old selfie doc
      if resp.success?
        correct_oriented_selfie = resp.data

        @new_selfie_s3_file_name = upload_image(@decrypted_user_data[:selfie_file_path],
                                                correct_oriented_selfie[:rotation_angle], correct_oriented_selfie[:rotated_image_path])

        selfie_dimensions = {
            width: correct_oriented_selfie[:width],
            height: correct_oriented_selfie[:height]
        }
        converted_from_pdf ? selfie_dimensions.merge!(pdf_rotation_angle: correct_oriented_selfie[:rotation_angle]) :
            selfie_dimensions.merge!(rotation_angle: correct_oriented_selfie[:rotation_angle])

        @user_kyc_comparison_detail.selfie_dimensions = selfie_dimensions
        @user_kyc_comparison_detail.save!
      else
        @new_selfie_s3_file_name = @decrypted_user_data[:selfie_file_path]
      end

      fetch_human_labels_from_selfie

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
    def make_ocr_comparisons(ocr_response, user_data)
      compare_params = {
          paragraph: ocr_response[:paragraph],
          dimensions: ocr_response[:word_dimensions],
          document_details: user_data
      }

      r = Ocr::CompareDocument.new(compare_params).perform
      rotation_angle = r.data[:rotation_angle]
      puts r.to_json

      if r.success? && r.data[:comparison_percent].present?
        r.data[:comparison_percent].each do |column, value|
          @user_kyc_comparison_detail["#{column.to_s}_match_percent".to_sym] = value
          # Delete from ocr unmatched if match found, to make further calls
          @ocr_unmatched.delete(column.to_s) if value.to_i == 100
        end
        @user_kyc_comparison_detail.save!
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
      zero_rotated_image = {}
      rotation_sequence.each do |rotate_angle|
        rotated_image = nil
        # Don't perform rotation once again for 0 angle, has already been done
        if rotate_angle == GlobalConstant::ImageProcessing.rotation_angle_0
          zero_rotated_image = @zero_rotated_documents[image_type]
          rotated_image = @zero_rotated_documents[image_type]
        else
          puts "#{rotate_angle} - Image Rotation started"
          resp = FileProcessing::RmagickImageRotation.new(file_directory, original_file, rotate_angle).perform
          return error_with_data("cr_pusi_4", "Rotate image failed", "Rotate image failed", nil, zero_rotated_image) unless resp.success?
          rotated_image = resp.data
        end

        # Call Vision detect face
        if rotated_image.present?
          puts "#{rotate_angle} - Vision detect face started"
          r = Google::VisionService.new.detect_faces(rotated_image[:rotated_image_path])
          log_resp = r.success? ? {faces: r.data[:faces], request_time: r.data[:request_time]} : r.to_json
          add_image_process_log(GlobalConstant::ImageProcessing.google_vision_detect_face,
                                {rotation_angle: rotate_angle, image_type: image_type}, log_resp)
          # Break this loop if its an error
          return error_with_data("cr_pusi_5", "Detect face failed", "Detect face failed", nil, zero_rotated_image) unless r.success?
          # If face is detected then stop further calls
          return success_with_data(rotated_image) if r.data[:faces].present? and r.data[:faces].length > 0
        end
      end

      # If face is not detected throughout assume zero rotated image as correct
      return success_with_data(zero_rotated_image)
    end

    # Download images from s3
    #
    # * Author: Pankaj
    # * Date: 02/07/2018
    # * Reviewed By:
    #
    # @return String - Downloaded image path
    #
    def download_file(s3_file_path, is_image)
      puts "#{s3_file_path} - Image downloading started"
      downloaded_file_name = s3_file_path.split("/").last
      local_file_path = "#{file_directory}/#{downloaded_file_name}"
      local_file_path += ".jpg" if is_image

      Aws::S3Manager.new('kyc', 'admin').get(local_file_path, s3_file_path, GlobalConstant::Aws::Common.kyc_bucket)
      local_file_path
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
      s3_file_name = "#{file_name}_#{rotation_angle}"
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
        shared_dir = GlobalConstant::Base.kyc_app['shared_directory']
        @dir = shared_dir.to_s + "/app_data/#{Rails.env}/images/#{@shard_identifier}" + "/#{@user_kyc_comparison_detail.id}"
        Util::FileSystem.check_and_create_directory(@dir)
      end
      @dir
    end

    # Get local cipher object
    #
    # * Author: Pankaj
    # * Date: 02/07/2018
    # * Reviewed By:
    #
    # @return [LocalCipher]
    #
    def get_local_cipher_object(kyc_salt = nil)
      @lco ||= LocalCipher.new(kyc_salt)
    end

    # Make an entry in image process log
    #
    # * Author: Pankaj
    # * Date: 02/07/2018
    # * Reviewed By:
    #
    def add_image_process_log(service, input, debug_data)
      encr_data = get_local_cipher_object.encrypt(debug_data.to_json).data[:ciphertext_blob]
      ImageProcessingLog.using_shard(shard_identifier: @shard_identifier).create!(
          user_kyc_comparison_detail_id: @user_kyc_comparison_detail.id,
          service_used: service,
          input_params: input,
          debug_data: encr_data)
    rescue => e
      ApplicationMailer.notify(
          body: e.backtrace,
          data: {client_id: @user_kyc_comparison_detail.client_id,
                 user_kyc_comparison_detail: @user_kyc_comparison_detail.id, message: e.message},
          subject: "Could not create ImageProcessingLog"
      ).deliver
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
      if resp.success?

        max_height, second_max_height = 0, 0

        @user_kyc_comparison_detail.big_face_match_percent = nil
        resp.data[:face_matches].present? && resp.data[:face_matches].each do |fm|
          current_height = fm[:face_bounding_box][:bounding_box][:height]

          # Check for bigger face and smaller face percentages
          if current_height >= max_height
            second_max_height = max_height
            @user_kyc_comparison_detail.small_face_match_percent = @user_kyc_comparison_detail.big_face_match_percent

            max_height = current_height
            @user_kyc_comparison_detail.big_face_match_percent = fm[:similarity_percent]
          elsif current_height >= second_max_height
            second_max_height = current_height
            @user_kyc_comparison_detail.small_face_match_percent = fm[:similarity_percent]
          end
        end

        @user_kyc_comparison_detail.small_face_match_percent ||= 0
        @user_kyc_comparison_detail.big_face_match_percent ||= 0
        @user_kyc_comparison_detail.save!
      end

      log_resp = resp.success? ? {face_matches: resp.data[:face_matches], document_has_face: resp.data[:document_has_face],
                                  document_face_bounding_box: resp.data[:document_face_bounding_box],
                                  request_time: resp.data[:request_time]} : resp.to_json
      add_image_process_log(GlobalConstant::ImageProcessing.aws_rekognition_compare_face,
                            {document: @new_doc_s3_file_name, selfie: @new_selfie_s3_file_name}, log_resp)

      success
    end

    # Make aws text detect call if any unmatched data is present
    #
    # * Author: Pankaj
    # * Date: 09/07/2018
    # * Reviewed By:
    #
    def make_aws_text_detect_call
      # No unmatched columns found
      return if @ocr_unmatched.blank? || @new_doc_s3_file_name.blank?
      puts "AWS detect text started"

      resp = Aws::RekognitionService.new.detect_text(@new_doc_s3_file_name)
      log_resp = resp.success? ? {detected_text: resp.data[:detected_text], request_time: resp.data[:request_time]} : resp.to_json
      add_image_process_log(GlobalConstant::ImageProcessing.aws_rekognition_detect_text,
                            {document: @new_doc_s3_file_name}, log_resp)

      return unless resp.success?

      # Make ocr comparisons
      user_unmatched_data = {}
      @ocr_unmatched.each {|x| user_unmatched_data[x.to_sym] = @decrypted_user_data[x.to_sym]}
      paragraph = ""
      resp.data[:detected_text].each do |dt|
        paragraph += dt[:text] + "\n"
      end
      make_ocr_comparisons({paragraph: paragraph}, user_unmatched_data)

      success
    end

    # Fetch human labels from selfie image
    #
    # * Author: Pankaj
    # * Date: 28/09/2018
    # * Reviewed By:
    #
    def fetch_human_labels_from_selfie
      return if @new_selfie_s3_file_name.blank?
      puts "AWS detect labels started"

      labels = []
      resp = Aws::RekognitionService.new.detect_labels(@new_selfie_s3_file_name)

      labels = resp.data[:labels] if resp.success?

      add_image_process_log(GlobalConstant::ImageProcessing.aws_rekognition_detect_label,
                            {selfie: @new_doc_s3_file_name}, resp.to_json)

      if labels.present?
        human_percentages = {"human" => 0, "people" => 0, "person" => 0}
        labels.each do |label|
          if human_percentages.keys.include?(label[:name].to_s.downcase)
            human_percentages[label[:name].to_s.downcase] = label[:confidence].to_i
          end
        end

        human_percent = human_percentages.values.max

        @user_kyc_comparison_detail.selfie_human_labels_percent = human_percent
        @user_kyc_comparison_detail.save
      end

    end

    # Lock Id for table
    #
    # * Author: Pankaj
    # * Date: 02/07/2018
    # * Reviewed By:
    #
    # @eturns [String] table lock id
    #
    def table_lock_id
      @table_lock_id ||= "#{@cron_identifier}_#{Time.now.to_i}"
      @table_lock_id
    end

    # Trigger Auto approval for the processed image
    #
    # * Author: Pankaj
    # * Date: 09/07/2018
    # * Reviewed By:
    #
    def trigger_auto_approval
      AutoApproveUpdateJob.perform_now({
                                           client_id: @user_kyc_comparison_detail.client_id,
                                           user_extended_details_id: @user_kyc_comparison_detail.user_extended_detail_id
                                       })
    end

    # Convert pdf to image
    #
    # * Author: Pankaj
    # * Date: 09/07/2018
    # * Reviewed By:
    #
    def convert_to_image(pdf_file_path)
      puts "Convert pdf to image - #{pdf_file_path}"
      pdf_file = download_file(pdf_file_path, false)

      FileProcessing::PdfToImage.new(file_directory, pdf_file).perform
    end

    # Perform basic validation on files and convert them into zero rotated images if required
    #
    # * Author: Pankaj
    # * Date: 09/07/2018
    # * Reviewed By:
    #
    def perform_validation_and_basic_operation_on_files(s3_file_name, doc_type)
      converted_from_pdf = false
      res_val = validate_image_file_name(s3_file_name)
      if !res_val.success? && res_val.error_message == "invalid_type"
        image_result = convert_to_image(s3_file_name)
        unless image_result.success?
          if doc_type == "document"
            update_user_comparison_record(GlobalConstant::KycAutoApproveFailedReason.document_file_invalid,
                                          GlobalConstant::ImageProcessing.failed_image_process_status)
          else
            update_user_comparison_record(GlobalConstant::KycAutoApproveFailedReason.selfie_file_invalid, nil)
          end
          return image_result
        end
        original_downloaded_image = image_result.data[:image_path]
        converted_from_pdf = true
      else
        original_downloaded_image = download_file(s3_file_name, true)
      end

      # Rotate image at 0 degree angle to remove its metadata
      strip_image_result = FileProcessing::RmagickImageRotation.new(file_directory, original_downloaded_image,
                                                                    GlobalConstant::ImageProcessing.rotation_angle_0).perform

      # If first rotation of image failed then close the process
      return strip_image_result unless strip_image_result.success?

      @zero_rotated_documents[doc_type] = strip_image_result.data

      success_with_data({original_downloaded_image: original_downloaded_image, converted_from_pdf: converted_from_pdf})
    end

  end

end

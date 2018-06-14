module Google

  class VisionService

    require "google/cloud/vision"

    include ::Util::ResultHelper

    # Initialize
    #
    # * Author: Sachin
    # * Date: 13/06/2018
    # * Reviewed By:
    #
    # @return [Aws::RekognitionService]
    #
    def initialize()

    end

    # Detect Text from the document image
    #
    # * Author: Sachin
    # * Date: 13/06/2018
    # * Reviewed By:
    #
    def detect_text(user_id, document_file = nil)
      if document_file.nil?
        r = fetch_file_names(user_id)
        return r unless r.success?

        document_file = r.data[:doc_path]
      end

      return error_with_data("Files Not found",
                             "Files Not found", "Files Not found",
                             "", "") if document_file.nil?

      api_call_detect_text(document_file)

    rescue => e
      data = {err: e.message}
      return exception_with_data(e, "Exception", "", "", "", data)

    end

    def api_call_detect_text(document_file)

      #vision client
      vision_client = client

      image = vision_client.image(get_url(document_file))
      # image = vision_client.image(document_file)

      annotation = vision_client.annotate(image, text: true)

      # # image.context.languages = ["en"]
      format_detect_text_response annotation.text
    end

    private

    # Get Url S3
    #
    # * Author: Sachin
    # * Date: 13/06/2018
    # * Reviewed By:
    #
    # @return [Google::Vision]
    #
    def get_url(s3_path)
      return '' unless s3_path.present?

      Aws::S3Manager.new('kyc', 'admin').
          get_signed_url_for(GlobalConstant::Aws::Common.kyc_bucket, s3_path)
    end

    # Get Google Vision object
    #
    # * Author: Sachin
    # * Date: 13/06/2018
    # * Reviewed By:
    #
    # @return [Google::Vision]
    #
    def client
      ## Note:: For authentication define GOOGLE_APPLICATION_CREDENTIALS which is credential file path
      project_id = 'sixth-drive-207107'
      Google::Cloud::Vision.new project: project_id
    end

    # Fetch different files of user
    #
    # * Author: Sachin
    # * Date: 13/06/2018
    # * Reviewed By:
    #
    def fetch_file_names(user_id)
      ukc = UserKycDetail.where(user_id: user_id).first

      return error_with_data("Not found", "User not found", "User not found", "", "") if ukc.nil?

      ued = UserExtendedDetail.where(id: ukc.user_extended_detail_id).first

      r = Aws::Kms.new('kyc', 'admin').decrypt(ued.kyc_salt)

      kyc_salt_d = r.data[:plaintext]

      local_cipher_obj = LocalCipher.new(kyc_salt_d)

      data = {}
      data[:doc_path] = local_cipher_obj.decrypt(ued.document_id_file_path).data[:plaintext] if ued.document_id_file_path.present?
      data[:selfie_path] = local_cipher_obj.decrypt(ued.selfie_file_path).data[:plaintext] if ued.selfie_file_path.present?
      data[:bucket] = GlobalConstant::Aws::Common.kyc_bucket

      success_with_data(data)
    end


    # Method to format detect text response
    #
    # * Author: Sachin
    # * Date: 13/06/2018
    # * Reviewed By:
    #
    def format_detect_text_response(annotate_text)
      start_time = current_time_in_milli
      resp_hash = annotate_text.to_h
      resp = resp_hash[:text].split(' ')
      end_time = current_time_in_milli
      # data = {document_has_text: !resp.blank?, request_time: (end_time - start_time)}
      data = {document_has_text: !resp.blank?, request_time: (end_time - start_time), response_data: annotate_text.to_h[:text]}


      unless resp.blank?
        data[:detected_text] = []
        resp.each do |x|
          data[:detected_text] << {text: x,
                                   confidence_percent: 100}
        end
      end

      return success_with_data(data)

    end

    def current_time_in_milli
      (Time.now.to_f * 1000).to_i
    end

  end
end
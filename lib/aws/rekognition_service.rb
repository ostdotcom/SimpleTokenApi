module Aws

  class RekognitionService

    include ::Util::ResultHelper

    # Initialize
    #
    # * Author: Pankaj
    # * Date: 07/06/2018
    # * Reviewed By:
    #
    # @return [Aws::RekognitionService]
    #
    def initialize()

    end

    # Compare faces in document file and selfie file of user
    #
    # * Author: Pankaj
    # * Date: 07/06/2018
    # * Reviewed By:
    #
    def compare_faces(user_id, similarity_treshold=0, document_file=nil, selfie_file=nil)
      if document_file.nil?
        r = fetch_file_names(user_id)
        return r unless r.success?

        document_file = r.data[:doc_path]
        selfie_file = r.data[:selfie_path]
      end

      return error_with_data("Files Not found",
                             "Files Not found", "Files Not found",
                             "", "") if document_file.nil? || selfie_file.nil?

      req_params = {
        similarity_threshold: similarity_treshold,
        source_image: {
          s3_object: {
            bucket: GlobalConstant::Aws::Common.kyc_bucket,
            name: document_file,
          }
        },
        target_image: {
          s3_object: {
            bucket: GlobalConstant::Aws::Common.kyc_bucket,
            name: selfie_file,
          }
        }
      }

      format_compare_faces_response(req_params)
    end

    # Detect Text from the document image
    #
    # * Author: Pankaj
    # * Date: 07/06/2018
    # * Reviewed By:
    #
    def detect_text(user_id, document_file=nil)
      if document_file.nil?
        r = fetch_file_names(user_id)
        return r unless r.success?

        document_file = r.data[:doc_path]
      end

      return error_with_data("Files Not found",
                             "Files Not found", "Files Not found",
                             "", "") if document_file.nil?

      req_params = {
          image: {
              s3_object: {
                  bucket: GlobalConstant::Aws::Common.kyc_bucket,
                  name: document_file,
              }
          }
      }

      format_detect_text_response(req_params)
    end

    private

    # Access key
    #
    # * Author: Pankaj
    # * Date: 07/06/2018
    # * Reviewed By:
    #
    # @return [String] returns access key for AWS
    #
    def access_key_id
      credentials['access_key']
    end

    # Secret key
    #
    # * Author: Pankaj
    # * Date: 07/06/2018
    # * Reviewed By:
    #
    # @return [String] returns secret key for AWS
    #
    def secret_key
      credentials['secret_key']
    end

    # Region
    #
    # * Author: Pankaj
    # * Date: 07/06/2018
    # * Reviewed By:
    #
    # @return [String] returns region
    #
    def region
      GlobalConstant::Aws::Common.region
    end

    # Credentials
    #
    # * Author: Pankaj
    # * Date: 07/06/2018
    # * Reviewed By:
    #
    # @return [Hash] returns Hash of AWS credentials
    #
    def credentials
      @credentials ||= GlobalConstant::Aws::Common.get_credentials_for('admin')
    end

    # Get Aws Rekognition object
    #
    # * Author: Pankaj
    # * Date: 07/06/2018
    # * Reviewed By:
    #
    # @return [Aws::Rekognition::Client]
    #
    def client
      @client ||= Aws::Rekognition::Client.new(
          access_key_id: access_key_id,
          secret_access_key: secret_key,
          region: region
      )
    end

    # Fetch different files of user
    #
    # * Author: Pankaj
    # * Date: 07/06/2018
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

    # Method to format compare faces response
    #
    # * Author: Pankaj
    # * Date: 07/06/2018
    # * Reviewed By:
    #
    def format_compare_faces_response(req_params)
      start_time = current_time_in_milli
      begin
        resp = client.compare_faces(req_params).to_h
        end_time = current_time_in_milli
        data = {document_has_face: resp[:source_image_face][:confidence],
                document_face_bounding_box: resp[:source_image_face][:bounding_box],
                request_time: (end_time-start_time)}

        if resp[:face_matches].present?
          data[:face_matches] = []
          resp[:face_matches].each do |x|
            data[:face_matches] << {similarity_percent: x[:similarity],
                                    face_bounding_box: x[:face]}
          end
        end

        data.merge!({unmatched_faces: resp[:unmatched_faces],
                     source_image_orientation_correction: resp[:source_image_orientation_correction],
                     target_image_orientation_correction: resp[:target_image_orientation_correction]})

        return success_with_data(data)

      rescue => e
        data = {err: e.message, request_time: (current_time_in_milli-start_time)}
        return error_with_data("Exception", "", "", "", data)
      end

    end

    # Method to format detect text reponse
    #
    # * Author: Pankaj
    # * Date: 07/06/2018
    # * Reviewed By:
    #
    def format_detect_text_response(req_params)
      start_time = current_time_in_milli
      begin
        resp = client.detect_text(req_params).to_h
        end_time = current_time_in_milli
        data = {document_has_text: resp[:text_detections].present?, request_time: (end_time-start_time)}

        if resp[:text_detections].present?
          data[:detected_text] = []
          resp[:text_detections].each do |x|
            data[:detected_text] << {text: x[:detected_text],
                                    confidence_percent: x[:confidence]}
          end
        end

        return success_with_data(data)

      rescue => e
        data = {err: e.message, request_time: (current_time_in_milli-start_time)}
        return exception_with_data(e,"Exception", "", "", "", data)
      end

    end

    def current_time_in_milli
      (Time.now.to_f * 1000).to_i
    end

  end

end
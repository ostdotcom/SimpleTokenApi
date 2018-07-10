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
    def compare_faces(document_file, selfie_file, similarity_treshold=0)

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
    def detect_text(document_file)

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
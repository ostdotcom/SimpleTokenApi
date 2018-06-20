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

    def api_call_detect_text(document_file)

      #vision client
      vision_client = client

      # image_object = vision_client.image get_url(document_file)
      image_object = vision_client.image document_file

      format_detect_text_response(image_object)
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
      ## Note:: For authentication define GOOGLE_APPLICATION_CREDENTIALS to define credential file path
      # and VISION_PROJECT_ID  to define project id environment variables.

      project_id = ENV['VISION_PROJECT_ID']
      Google::Cloud::Vision.new project: project_id
    end


    # Method to format detect text response
    #
    # * Author: Sachin
    # * Date: 13/06/2018
    # * Reviewed By:
    #
    def format_detect_text_response(image_object)
      start_time = current_time_in_milli
      resp_object = image_object.document
      end_time = current_time_in_milli

      puts resp_object

      text_string = resp_object.text

      words_array = resp_object.words

      orientation = get_orientation(words_array)

      success_with_data({words_array: text_string, request_time: (end_time - start_time), orientation: orientation})
    rescue => e
      data = {debug_data: {err: e.message.to_json}, request_time: 0 }
      error_with_data("Exception", "", "", "", data)
    end

    def current_time_in_milli
      (Time.now.to_f * 1000).to_i
    end


    def get_orientation(words_array)

      x_diff = 0
      y_diff = 0

      (1..(words_array.length-1)).each do |index|
        x_diff+=words_array[index].bounds[0].x - words_array[index-1].bounds[0].x
        y_diff+=words_array[index].bounds[0].y - words_array[index-1].bounds[0].y
      end

      puts x_diff
      puts y_diff

      max_value = [x_diff.abs,y_diff.abs].max

      # y is greater and positive normal
      # x is greater and positive right
      # y is greater and negative inverted
      # x is greater and negative left


      if x_diff == y_diff
        return 'UNDEFINED'
      end
      if  max_value == x_diff.abs
        if x_diff < 0
          return 'ROTATE_270'
        else
          return 'ROTATE_90'
        end
      else
        if y_diff < 0
          return 'ROTATE_180'
        else
          return 'ROTATE_0'
        end
      end
    end

  end
end


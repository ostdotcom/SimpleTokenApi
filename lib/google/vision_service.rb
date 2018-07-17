module Google

  class VisionService

    require "google/cloud/vision"

    include ::Util::ResultHelper

    S3_DOCUMENT_IMAGE_PATH_REGEX = /\A([A-Z0-9\/]*\/)*i\/[A-Z0-9\/]+\Z/i

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

    # Api call to vision google client
    #
    # * Author: Sachin
    # * Date: 13/06/2018
    # * Reviewed By:
    #
    # @return [Google::Vision]
    #
    def api_call_detect_text(document_file)

      #vision client
      vision_client = client

      # resp = validate_image_file_name(document_file)
      # return resp unless resp.success?
      #
      # Aws::S3Manager.new('kyc', 'admin').get(ENV['VISION_IMAGE_PATH'], document_file,
      #                                        GlobalConstant::Aws::Common.kyc_bucket)

      image_object = vision_client.image document_file

      format_detect_text_response(image_object)
    end

    # Api call to vision google client
    #
    # * Author: Sachin
    # * Date: 13/06/2018
    # * Reviewed By:
    #
    # @return [Google::Vision]
    #
    def api_call_detect_faces(document_file)

      #vision client
      vision_client = client

      faces_object = vision_client.image document_file

      format_detect_faces_response(faces_object)
    end

    def validate_image_file_name(document_file)
      puts document_file
      if !(document_file =~ UserManagement::KycSubmit::S3_DOCUMENT_PATH_REGEX)
        data = {debug_data: {error_type: 'invalid_document_file_name'}, request_time: 0}
        return error_with_data("Exception in s3 document path", "", "s3 path invalid", "", data)
      end

      if !(document_file =~ S3_DOCUMENT_IMAGE_PATH_REGEX)
        data = {debug_data: {error_type: 'invalid_file_type'}, request_time: 0}
        return error_with_data("pdf_file", "pdf_file", "pdf_file", "", data)
      end

      return success
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


    def current_time_in_milli
      (Time.now.to_f * 1000).to_i
    end

    # Method to format detect faces response
    #
    # * Author: Sachin
    # * Date: 13/06/2018
    # * Reviewed By:
    #
    def format_detect_faces_response(image_object)
      start_time = current_time_in_milli
      resp_object = image_object.faces
      end_time = current_time_in_milli

      if (resp_object.nil?)
        return error_with_data("Exception in image.faces", "", "nil response", "", {})
      end

      success_with_data({faces: resp_object.length, request_time: (end_time - start_time)})
    rescue => e
      data = {debug_data: {err: e.message.to_json}, request_time: 0}
      error_with_data("Exception", "", "", "", data)
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

    if (resp_object.nil?)
      return error_with_data("Exception in image.document", "", "nil response", "", {})
    end

    text_string = resp_object.text

    words_array = resp_object.words

    orientation = get_orientation(words_array)

    success_with_data({words_array: text_string, request_time: (end_time - start_time), orientation: orientation})
  rescue => e
    data = {debug_data: {err: e.message.to_json}, request_time: 0}
    error_with_data("Exception", "", "", "", data)
  end


  def get_orientation(words_array)

    orientation_data = {
        'UNDEFINED' => 0,
        'ROTATE_0' => 0,
        'ROTATE_90' => 0,
        'ROTATE_270' => 0,
        'ROTATE_180' => 0
    }


    (0..(words_array.length - 1)).each do |index|

      x_diff = 0
      y_diff = 0
      orientation = nil

      word = words_array[index]

      next if word.nil? || word.text.size < 3

      x1 = words_array[index].bounds[0].x
      y1 = words_array[index].bounds[0].y

      x2 = words_array[index].bounds[1].x
      y2 = words_array[index].bounds[1].y

      x_diff = (x2 - x1)
      y_diff = (y2 - y1)

      # x is greater and positive : normal orientation
      # x is greater and negative : inverted orientation
      # y is greater and positive : left orientation
      # y is greater and negative : right orientation

      if x_diff.abs == y_diff.abs
        orientation = 'UNDEFINED'
      end

      if x_diff.abs > y_diff.abs
        if x_diff < 0
          orientation = 'ROTATE_180'
        else
          orientation = 'ROTATE_0'
        end
      else
        if y_diff < 0
          orientation = 'ROTATE_90'
        else
          orientation = 'ROTATE_270'
        end
      end

      orientation_data[orientation] += 1
    end

    max_orientation = nil
    max_count = 0

    orientation_data.each do |orientation, count|
      if count > max_count
        max_orientation = orientation
        max_count = count
      end
    end

    return max_orientation
  end

  end
end



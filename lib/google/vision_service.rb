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
    # @return [Google::VisionService]
    #
    def initialize()

    end

    # Detect text from the image
    #
    # * Author: Pankaj
    # * Date: 04/07/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def detect_text(image_path)

      image_object = client.image image_path

      start_time = current_time_in_milli
      begin
        resp_object = image_object.document

        text_paragraph = resp_object.text

        word_dimensions = resp_object.words

        return success_with_data({paragraph: text_paragraph, word_dimensions: word_dimensions,
                           request_time: (current_time_in_milli - start_time)})
      rescue => e
        return error_with_data("gvs_1",
                               e.message, e.message, "", {request_time: (current_time_in_milli - start_time)})
      end

    end


    # Detect Face from the image
    #
    # * Author: Pankaj
    # * Date: 04/07/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def detect_faces(image_path)

      image_object = client.image image_path

      start_time = current_time_in_milli
      begin
        resp_object = image_object.faces

        faces_data = []
        resp_object.present? && resp_object.each do |face_data|
          faces_data << {angles: face_data.angles, bounds: face_data.bounds}
        end

        return success_with_data({faces: faces_data, request_time: (current_time_in_milli - start_time)})
      rescue => e
        return error_with_data("gvs_2",
                               e.message, e.message, "", {request_time: (current_time_in_milli - start_time)})
      end

    end



    private

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

      project_id = GlobalConstant::Base.google_vision['project_id']
      Google::Cloud::Vision.new project: project_id
    end


    def current_time_in_milli
      (Time.now.to_f * 1000).to_i
    end

  end
end



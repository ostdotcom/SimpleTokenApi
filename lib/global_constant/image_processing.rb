# frozen_string_literal: true
module GlobalConstant

  class ImageProcessing

    class << self

      ### Services Type Start ###

      def google_vision_detect_text
        'vision_ocr'
      end

      def google_vision_detect_face
        'vision_face_detect'
      end

      def aws_rekognition_compare_face
        'rekognition_compare_face'
      end

      def aws_rekognition_detect_text
        'rekognition_detect_text'
      end

      ### Services Type End ###

    end

  end

end

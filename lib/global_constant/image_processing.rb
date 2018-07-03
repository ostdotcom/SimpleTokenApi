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

      ###### Image Processing statuses Start ######

      def unprocessed_image_process_status
        'unprocessed'
      end

      def processed_image_process_status
        'processed'
      end

      def failed_pdf_image_process_status
        'failed_pdf'
      end

      def failed_big_image_process_status
        'failed_big_image'
      end

      def failed_file_invalid_image_process_status
        'failed_file_invalid'
      end

      def failed_image_process_status
        'failed'
      end

      ###### Image Processing statuses End ######

    end

  end

end

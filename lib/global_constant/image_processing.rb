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

      def failed_invalid_document_file
        'invalid_document'
      end

      def failed_invalid_selfie_file
        'invalid_selfie'
      end

      def failed_vision_detect_text
        'vision_dt_failed'
      end

      def failed_aws_compare_faces
        'aws_cf_failed'
      end

      def failed_unmatched_faces
        'aws_cf_unmatched_faces'
      end

      ###### Image Processing statuses End ######

      ########## Rotation angles START ###########

      def rotation_angle_0
        'rotate_0'
      end

      def rotation_angle_90
        'rotate_90'
      end

      def rotation_angle_180
        'rotate_180'
      end

      def rotation_angle_270
        'rotate_270'
      end

      def rotation_angles
        {
            rotation_angle_0 => 0,
            rotation_angle_90 => 90,
            rotation_angle_180 => 180,
            rotation_angle_270 => 270
        }
      end

      def rotation_sequence
        [rotation_angle_0, rotation_angle_90, rotation_angle_270, rotation_angle_180]
      end

      ########## Rotation angles End ###########
    end

  end

end

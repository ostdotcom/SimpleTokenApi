class ImageProcessingLog < EstablishSimpleTokenLogDbConnection


  module Methods
    extend ActiveSupport::Concern
    included do

      enum service_used: {
          GlobalConstant::ImageProcessing.google_vision_detect_text => 1,
          GlobalConstant::ImageProcessing.google_vision_detect_face => 2,
          GlobalConstant::ImageProcessing.aws_rekognition_compare_face => 3,
          GlobalConstant::ImageProcessing.aws_rekognition_detect_text => 4,
          GlobalConstant::ImageProcessing.aws_rekognition_detect_label => 5
      }

    end

    module ClassMethods

    end
  end


end

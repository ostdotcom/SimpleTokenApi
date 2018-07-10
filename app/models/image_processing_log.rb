class ImageProcessingLog < EstablishSimpleTokenLogDbConnection

  enum service_used: {
      GlobalConstant::ImageProcessing.google_vision_detect_text => 1,
      GlobalConstant::ImageProcessing.google_vision_detect_face => 2,
      GlobalConstant::ImageProcessing.aws_rekognition_compare_face => 3,
      GlobalConstant::ImageProcessing.aws_rekognition_detect_text => 4
  }
end

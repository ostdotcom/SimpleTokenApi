class UserKycComparisonDetail < EstablishSimpleTokenUserDbConnection

  enum image_processing_status: {
    GlobalConstant::ImageProcessing.unprocessed_image_process_status => 0,
    GlobalConstant::ImageProcessing.processed_image_process_status => 1,
    GlobalConstant::ImageProcessing.failed_invalid_document_file => 2,
    GlobalConstant::ImageProcessing.failed_invalid_selfie_file => 3,
    GlobalConstant::ImageProcessing.failed_vision_detect_text => 4,
    GlobalConstant::ImageProcessing.failed_aws_compare_faces => 5,
    GlobalConstant::ImageProcessing.failed_unmatched_faces => 6
  }
end

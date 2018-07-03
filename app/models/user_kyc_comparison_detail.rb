class UserKycComparisonDetail < EstablishSimpleTokenUserDbConnection

  enum image_processing_status: {
    GlobalConstant::ImageProcessing.unprocessed_image_process_status => 0,
    GlobalConstant::ImageProcessing.processed_image_process_status => 1,
    GlobalConstant::ImageProcessing.failed_image_process_status => 2,
    GlobalConstant::ImageProcessing.failed_file_invalid_image_process_status => 3,
    GlobalConstant::ImageProcessing.failed_pdf_image_process_status => 4,
    GlobalConstant::ImageProcessing.failed_big_image_process_status => 5
  }
end

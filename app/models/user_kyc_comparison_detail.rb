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


  def self.auto_approve_failed_reason

    @auto_approve_failed_reason ||= {
        GlobalConstant::KycAutoApproveFailedReason.document_file_invalid => 1,
        GlobalConstant::KycAutoApproveFailedReason.selfie_file_invalid => 2,
        GlobalConstant::KycAutoApproveFailedReason.ocr_unmatch=> 4,
        GlobalConstant::KycAutoApproveFailedReason.fr_unmatch => 8,
        GlobalConstant::KycAutoApproveFailedReason.residency_proof => 16,
        GlobalConstant::KycAutoApproveFailedReason.investor_proof => 32,
        GlobalConstant::KycAutoApproveFailedReason.duplicate_kyc => 64,
        GlobalConstant::KycAutoApproveFailedReason.token_sale_ended => 128,
        GlobalConstant::KycAutoApproveFailedReason.unexpected => 256
    }

  end

  def auto_approve_failed_reason_array
    @auto_approve_failed_reason_array = UserKycComparisonDetail.get_bits_set_for_auto_approve_failed_reason(auto_approve_failed_reason)
  end

  # Bitwise columns config
  #
  # * Author: Aniket
  # * Date: 10/07/2018
  # * Reviewed By:
  #
  def self.bit_wise_columns_config
    @b_w_c_c ||= {
        auto_approve_failed_reason: auto_approve_failed_reason
    }
  end

  # Note : always include this after declaring bit_wise_columns_config method
  include BitWiseConcern


  # Get OCR Comparison Bitwise Value
  #
  # * Author: Aniket
  # * Date: 04/07/2018
  # * Reviewed By
  #
  def self.auto_approve_failed_reason_bit_value(reasons_array)
    ocr_comparison_value = 0
    reasons_array.each do |reason|
      ocr_comparison_value += UserKycComparisonDetail.auto_approve_failed_reason[reason]
    end

    ocr_comparison_value
  end
end

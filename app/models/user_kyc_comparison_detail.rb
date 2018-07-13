class UserKycComparisonDetail < EstablishSimpleTokenUserDbConnection

  after_commit :memcache_flush

  enum image_processing_status: {
    GlobalConstant::ImageProcessing.unprocessed_image_process_status => 0,
    GlobalConstant::ImageProcessing.processed_image_process_status => 1,
    GlobalConstant::ImageProcessing.failed_image_process_status => 2
  }

  serialize :document_dimensions, Hash
  serialize :selfie_dimensions, Hash


  def self.auto_approve_failed_reasons_config
    @auto_approve_failed_reasons_config ||= {
        GlobalConstant::KycAutoApproveFailedReason.document_file_invalid => 1,
        GlobalConstant::KycAutoApproveFailedReason.selfie_file_invalid => 2,
        GlobalConstant::KycAutoApproveFailedReason.ocr_unmatch=> 4,
        GlobalConstant::KycAutoApproveFailedReason.fr_unmatch => 8,
        GlobalConstant::KycAutoApproveFailedReason.residency_proof => 16,
        GlobalConstant::KycAutoApproveFailedReason.investor_proof => 32,
        GlobalConstant::KycAutoApproveFailedReason.duplicate_kyc => 64,
        GlobalConstant::KycAutoApproveFailedReason.token_sale_ended => 128,
        GlobalConstant::KycAutoApproveFailedReason.unexpected_reason => 256,
        GlobalConstant::KycAutoApproveFailedReason.unmatched_faces_in_selfie => 512
    }
  end

  def auto_approve_failed_reasons_array
    @auto_approve_failed_reasons_array = UserKycComparisonDetail.get_bits_set_for_auto_approve_failed_reasons(auto_approve_failed_reasons)
  end

  # Bitwise columns config
  #
  # * Author: Aniket
  # * Date: 10/07/2018
  # * Reviewed By:
  #
  def self.bit_wise_columns_config
    @b_w_c_c ||= {
        auto_approve_failed_reason: auto_approve_failed_reasons_config
    }
  end

  # Note : always include this after declaring bit_wise_columns_config method
  include BitWiseConcern


  # Get Key Object
  #
  # * Author: Aniket
  # * Date: 12/07/2018
  # * Reviewed By:
  #
  # @return [MemcacheKey] Key Object
  #
  def self.get_by_ued_memcache_key_object
    MemcacheKey.new('user.user_kyc_comparison_detail')
  end

  # Get/Set user kyc comparison detail for Client
  #
  # * Author: Aniket
  # * Date: 12/07/2018
  # * Reviewed By:
  #
  # @param [Integer] client_id - client id
  #
  # @return [AR] UserKycComparisonDetail object
  #
  def self.get_by_ued_from_memcache(user_extended_detail_id)
    memcache_key_object = UserKycComparisonDetail.get_by_ued_memcache_key_object
    Memcache.get_set_memcached(memcache_key_object.key_template % {user_extended_detail_id: user_extended_detail_id}, memcache_key_object.expiry) do
      UserKycComparisonDetail.where(user_extended_detail_id: user_extended_detail_id).first
    end
  end


  # Get OCR Comparison Bitwise Value
  #
  # * Author: Aniket
  # * Date: 04/07/2018
  # * Reviewed By:
  #
  def self.auto_approve_failed_reasons_bit_value(reasons_array)
    ocr_comparison_value = 0
    reasons_array.each do |reason|
      ocr_comparison_value += UserKycComparisonDetail.auto_approve_failed_reasons[reason]
    end

    ocr_comparison_value
  end


  # Flush Memcache
  #
  # * Author: Aniket/Tejas
  # * Date: 12/07/2018
  # * Reviewed By:
  #
  def memcache_flush
    client_memcache_key = UserKycComparisonDetail.get_by_ued_memcache_key_object.key_template % {user_extended_detail_id: self.user_extended_detail_id}
    Memcache.delete(client_memcache_key)
  end
end

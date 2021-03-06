class UserKycComparisonDetail

  module Methods
    extend ActiveSupport::Concern

    included do

      serialize :document_dimensions, Hash
      serialize :selfie_dimensions, Hash

      after_commit :memcache_flush

      enum image_processing_status: {
          GlobalConstant::ImageProcessing.unprocessed_image_process_status => 0,
          GlobalConstant::ImageProcessing.processed_image_process_status => 1,
          GlobalConstant::ImageProcessing.failed_image_process_status => 2
      }

      serialize :document_dimensions, Hash
      serialize :selfie_dimensions, Hash


      def auto_approve_failed_reasons_array
        @auto_approve_failed_reasons_array = self.singleton_class.get_bits_set_for_auto_approve_failed_reasons(auto_approve_failed_reasons)
      end

      # Flush Memcache
      #
      # * Author: Aniket/Tejas
      # * Date: 12/07/2018
      # * Reviewed By:
      #
      def memcache_flush
        ukcd_memcache_key = self.singleton_class.get_by_ued_memcache_key_object.key_template % {
            user_extended_detail_id: self.user_extended_detail_id,
            shard_identifier: self.singleton_class.shard_identifier
        }
        Memcache.delete(ukcd_memcache_key)
      end

      # Note : always include this after declaring bit_wise_columns_config method
      include BitWiseConcern
    end


    module ClassMethods

      def auto_approve_failed_reasons_config
        @auto_approve_failed_reasons_config ||= {
            GlobalConstant::KycAutoApproveFailedReason.unexpected_reason => 1,
            GlobalConstant::KycAutoApproveFailedReason.document_file_invalid => 2,
            GlobalConstant::KycAutoApproveFailedReason.selfie_file_invalid => 4,

            GlobalConstant::KycAutoApproveFailedReason.ocr_unmatch=> 8,
            GlobalConstant::KycAutoApproveFailedReason.fr_unmatch => 16,
            GlobalConstant::KycAutoApproveFailedReason.residency_proof => 32,
            GlobalConstant::KycAutoApproveFailedReason.investor_proof => 64,
            GlobalConstant::KycAutoApproveFailedReason.duplicate_kyc => 128,
            GlobalConstant::KycAutoApproveFailedReason.token_sale_ended => 256,
            GlobalConstant::KycAutoApproveFailedReason.case_closed_for_auto_approve => 512,
            GlobalConstant::KycAutoApproveFailedReason.human_labels_percentage_low => 1024
        }
      end

      # Bitwise columns config
      #
      # * Author: Aniket
      # * Date: 10/07/2018
      # * Reviewed By:
      #
      def bit_wise_columns_config
        @b_w_c_c ||= {
            auto_approve_failed_reasons: auto_approve_failed_reasons_config
        }
      end


      # Get Key Object
      #
      # * Author: Aniket
      # * Date: 12/07/2018
      # * Reviewed By:
      #
      # @return [MemcacheKey] Key Object
      #
      def get_by_ued_memcache_key_object
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
      def get_by_ued_from_memcache(user_extended_detail_id)
        memcache_key_object = self.get_by_ued_memcache_key_object

        Memcache.get_set_memcached(memcache_key_object.key_template % {
            user_extended_detail_id: user_extended_detail_id,
            shard_identifier: self.shard_identifier
        }, memcache_key_object.expiry) do
          self.where(user_extended_detail_id: user_extended_detail_id).first
        end
      end


    end

  end

end

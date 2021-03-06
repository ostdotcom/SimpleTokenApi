# frozen_string_literal: true
module GlobalConstant
  class KycAutoApproveFailedReason

    class << self

      def ocr_unmatch
        'ocr_unmatch'
      end

      def fr_unmatch
        'fr_unmatch'
      end

      def residency_proof
        'residency_proof'
      end

      def investor_proof
        'investor_proof'
      end

      def duplicate_kyc
        'duplicate_kyc'
      end

      def token_sale_ended
        'token_sale_ended'
      end

      def case_closed_for_auto_approve
        'case_closed_for_auto_approve'
      end

      def human_labels_percentage_low
        'human_labels_percentage_low'
      end

      def document_file_invalid
        'document_file_invalid'
      end

      def selfie_file_invalid
        'selfie_file_invalid'
      end

      def unexpected_reason
        'unexpected_reason'
      end


      def auto_approve_fail_reasons
        [
            ocr_unmatch,
            fr_unmatch,
            residency_proof,
            investor_proof,
            duplicate_kyc,
            token_sale_ended,
            case_closed_for_auto_approve,
            human_labels_percentage_low

        ]
      end

      def ocr_fr_review_type_failed_reasons
        [
            ocr_unmatch,
            fr_unmatch
        ]
      end

    end

  end
end

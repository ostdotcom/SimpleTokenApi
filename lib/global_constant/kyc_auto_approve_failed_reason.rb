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

      def document_file_invalid
        'document_file_invalid'
      end

      def selfie_file_invalid
        'selfie_file_invalid'
      end

      def unexpected
        'unexpected_reason'
      end

    end

  end
end

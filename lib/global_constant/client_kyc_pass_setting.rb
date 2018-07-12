# frozen_string_literal: true
module GlobalConstant

  class ClientKycPassSetting

    class << self

      ### Status Start ###

      def active_status
        'active'
      end

      def inactive_status
        'inactive'
      end

      ### Status End ###

      ### Kyc pass setting status for front Start ###

      def auto_approve_web_status
        'auto'
      end

      def manual_approve_web_status
        'manual'
      end

      ### Kyc Approve Type Status ###

      def auto_approve_type
        'auto'
      end

      def manual_approve_type
        'manual'
      end

      ### Kyc Auto approve setting status for front End ###

      def recommended_fr_percent
        '70'
      end

      ### OCR comparison column start ###

      def first_name_ocr_comparison_field
        'first_name'
      end

      def last_name_ocr_comparison_field
        'last_name'
      end

      def birthdate_ocr_comparison_field
        'birthdate'
      end

      def nationality_ocr_comparison_field
        'nationality'
      end

      def document_id_number_ocr_comparison_field
        'document_id_number'
      end

      ### OCR comparison column End ###

    end

  end

end

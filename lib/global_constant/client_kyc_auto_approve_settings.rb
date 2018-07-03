# frozen_string_literal: true
module GlobalConstant

  class ClientKycAutoApproveSettings

    class << self

      ### Status Start ###

      def active_status
        'active'
      end

      def inactive_status
        'inactive'
      end

      def web_status_auto
        'auto'
      end

      def web_status_manual
        'manual'
      end

      def recommended_fr_percent
        '70'
      end
      ### Status End ###

      ### OCR comparison column start ###

      def first_name_ocr_comparison_column
        'first_name_match'
      end

      def last_name_ocr_comparison_column
        'last_name_match'
      end

      def birthdate_ocr_comparison_column
        'birthdate_match'
      end

      def nationality_ocr_comparison_column
        'nationality_match'
      end

      def document_id_ocr_comparison_column
        'document_id_match'
      end

      ### OCR comparison column End ###

    end

  end

end

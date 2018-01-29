# frozen_string_literal: true
module GlobalConstant

  class UserKycDuplicationLog

    class << self

      ### Status Start ###

      def active_status
        'active'
      end

      def inactive_status
        'inactive'
      end

      ### Status End ###

      ### duplicate_type starts ####

      def document_id_with_country_duplicate_type
        'document_id_with_country'
      end

      def only_document_id_duplicate_type
        'only_document_id'
      end

      def ethereum_duplicate_type
        'ethereum'
      end

      def address_duplicate_type
        'address'
      end

      ### duplicate_type ends####

    end

  end

end

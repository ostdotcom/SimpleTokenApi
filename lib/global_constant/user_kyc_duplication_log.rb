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

      def passport_with_country_duplicate_type
        'passport_with_country'
      end

      def only_passport_duplicate_type
        'only_passport'
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

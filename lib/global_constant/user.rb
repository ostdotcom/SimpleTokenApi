# frozen_string_literal: true
module GlobalConstant

  class User

    class << self

      ### Status Start ###

      def active_status
        'active'
      end

      def inactive_status
        'inactive'
      end

      def deactived_status
        'deactived'
      end

      ### Status End ###

      ### Property start ###

      def bt_done_property
        'bt_done'
      end

      def kyc_optin_done_property
        'kyc_optin_done'
      end

      ### Property stop ###


    end

  end

end

# frozen_string_literal: true
module GlobalConstant

  class ClientWhitelistDetail

    class << self

      ### Status Start ###

      def active_status
        'active'
      end

      def inactive_status
        'inactive'
      end

      ### Status End ###

      ### Whitelisting Suspended type Start ###

      def not_suspended_type
        'is_not_suspended'
      end

      def low_balance_suspension_type
        'low_balance_suspended'
      end

      ### Whitelisting Suspended type End ###

      # Check whether whitelisting error is low eth balance error
      def low_balance_error?(err)
        err.match('low_eth_balance')
      end

    end

  end

end

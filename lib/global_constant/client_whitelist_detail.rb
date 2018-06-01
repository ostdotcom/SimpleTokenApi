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

      def no_suspension_type
        'no'
      end

      def low_balance_suspension_type
        'low_balance'
      end

      ### Whitelisting Suspended type End ###

      # Check whether whitelisting error is low eth balance error
      def low_balance_error?(err)
        err.match('low_eth_balance')
      end

    end

  end

end

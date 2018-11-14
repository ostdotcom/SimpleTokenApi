module Request
  module OpsApi

    class Whitelist < Request::OpsApi::Base

      # Initialize
      #
      # * Author: Aman
      # * Date: 25/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Request::OpsApi::Whitelist]
      #
      def initialize
        super
      end

      # Submit Whitelist to token sale contract
      #
      # * Author: Aman
      # * Date: 25/10/2017
      # * Reviewed By: Sunil
      #
      # @param [String] address (mandatory)
      # @param [Integer] phase (mandatory)
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def whitelist(params)
        send_request_of_type(GlobalConstant::PrivateOpsApi.private_ops_api_type, 'post', '/token-sale/whitelist', params)
      end

    end

  end

end

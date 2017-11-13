module OpsApi

  module Request

    class GetWhitelistStatus < OpsApi::Request::Base

      # Initialize
      #
      # * Author: Kedar
      # * Date: 26/10/2017
      # * Reviewed By: Sunil
      #
      # @return [OpsApi::Request::GetWhitelistStatus]
      #
      def initialize
        super
      end

      # Perform
      #
      # * Author: Kedar
      # * Date: 26/10/2017
      # * Reviewed By: Sunil
      #
      # @param [String] ethereum_address (mandatory)
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def perform(params)
        send_request_of_type(
          GlobalConstant::PublicOpsApi.public_ops_api_type, 'get', '/token-sale/whitelist-status', params
        )
      end

    end
  end
end

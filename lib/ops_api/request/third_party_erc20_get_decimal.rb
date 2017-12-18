module OpsApi

  module Request

    class ThirdPartyErc20GetDecimal < OpsApi::Request::Base

      # Initialize
      #
      # * Author: Aman
      # * Date: 15/12/2017
      # * Reviewed By:
      #
      # @return [OpsApi::Request::ThirdPartyErc20GetDecimal]
      #
      def initialize
        super
      end

      # Perform
      #
      # * Author: Aman
      # * Date: 15/12/2017
      # * Reviewed By:
      #
      # @param [String] ethereum_address (mandatory)
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def perform(params)
        send_request_of_type(
            GlobalConstant::PublicOpsApi.public_ops_api_type, 'get', '/third-party-contract/get-decimals', params
        )
      end

    end

  end

end

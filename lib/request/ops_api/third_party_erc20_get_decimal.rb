module Request
  module OpsApi

    class ThirdPartyErc20GetDecimal < Request::OpsApi::Base

      # Initialize
      #
      # * Author: Aman
      # * Date: 15/12/2017
      # * Reviewed By:
      #
      # @return [Request::OpsApi::ThirdPartyErc20GetDecimal]
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

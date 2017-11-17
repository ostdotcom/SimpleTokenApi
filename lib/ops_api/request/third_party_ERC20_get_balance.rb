module OpsApi

  module Request

    class ThirdPartyErc20GetBalance < OpsApi::Request::Base

      # Initialize
      #
      # * Author: Kushal, Alpesh
      # * Date: 17/11/2017
      # * Reviewed By:
      #
      # @return [OpsApi::Request::ThirdPartyERC20GetBalance]
      #
      def initialize
        super
      end

      # Perform
      #
      # * Author: Kushal, Alpesh
      # * Date: 17/11/2017
      # * Reviewed By:
      #
      # @param [String] contract_address (mandatory)#
      # @param [String] ethereum_address (mandatory)
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def perform(params)
        send_request_of_type(
          GlobalConstant::PublicOpsApi.public_ops_api_type, 'get', '/third-party-contract/get-balance', params
        )
      end

    end

  end

end

module OpsApi

  module Request

    class GetEthBalance < OpsApi::Request::Base

      # Initialize
      #
      # * Author: Kedar
      # * Date: 15/11/2017
      # * Reviewed By:
      #
      # @return [OpsApi::Request::GetEthBalance]
      #
      def initialize
        super
      end

      # Perform
      #
      # * Author: Kedar
      # * Date: 15/11/2017
      # * Reviewed By:
      #
      # @param [String] ethereum_address (mandatory)
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def perform(params)
        send_request_of_type(
          GlobalConstant::PublicOpsApi.public_ops_api_type, 'get', '/address/get-balance', params
        )
      end

    end

  end

end

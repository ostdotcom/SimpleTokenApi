module OpsApi

  module Request

    class ValidEthereumAddress < OpsApi::Request::Base

      # Initialize
      #
      # * Author: Abhay
      # * Date: 31/10/2017
      # * Reviewed By: Sunil
      #
      # @return [OpsApi::Request::ValidEthereumAddress]
      #
      def initialize
        super

        @timeouts = {write: 1, connect: 1, read: 1}
      end

      # Perform
      #
      # * Author: Abhay
      # * Date: 31/10/2017
      # * Reviewed By: Sunil
      #
      # @param [String] address (mandatory)
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def perform(params)
        send_request_of_type(GlobalConstant::PrivateOpsApi.private_ops_api_type, 'get', '/address/check', params)
      end

    end
  end
end

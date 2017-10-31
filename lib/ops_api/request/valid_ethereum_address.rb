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
      end

      # Perform
      #
      # * Author: Abhay
      # * Date: 31/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def perform(address)
        send_request_of_type(GlobalConstant::PrivateOpsApi.private_ops_api_type, 'get', '/address/check', {address: address})
      end

    end
  end
end

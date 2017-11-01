module OpsApi

  module Request

    class GetBlockInfo < OpsApi::Request::Base

      # Initialize
      #
      # * Author: Kedar
      # * Date: 26/10/2017
      # * Reviewed By: Sunil
      #
      # @return [OpsApi::Request::GetWhitelistConfirmation]
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
      # @return [Result::Base] returns an object of Result::Base class
      #
      def perform(token)
        send_request_of_type(GlobalConstant::PrivateOpsApi.private_ops_api_type, 'get', '/address/check', {token: token})
      end

    end
  end
end

module OpsApi

  module Request

    class Whitelist < OpsApi::Request::Base

      # Initialize
      #
      # * Author: Aman
      # * Date: 25/10/2017
      # * Reviewed By: Sunil
      #
      # @return [OpsApi::Request::Whitelist]
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
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def whitelist(token)
        send_request_of_type(GlobalConstant::PrivateOpsApi.private_ops_api_type, 'post', '/token-sale/whitelist', {token: token})
      end

    end

  end

end

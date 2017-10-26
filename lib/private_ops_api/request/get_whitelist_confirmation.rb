module PrivateOpsApi

  module Request

    class GetWhitelistConfirmation < Base

      # Initialize
      #
      # * Author: Kedar
      # * Date: 26/10/2017
      # * Reviewed By:
      #
      # @return [PrivateOpsApi::Request::GetWhitelistConfirmation]
      #
      def initialize
        super
      end

      # Perform
      #
      # * Author: Kedar
      # * Date: 26/10/2017
      # * Reviewed By:
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def perform(token)
        send_request_of_type('get', '/token-sale/whitelist', {token: token})
      end

    end
  end
end
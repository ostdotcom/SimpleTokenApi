module PrivateOpsApi
  module Request
    class Whitelist < Base

      # Initialize
      #
      # * Author: Aman
      # * Date: 25/10/2017
      # * Reviewed By:
      #
      # @return [PrivateOpsApi::Request::Whitelist] returns an object of PrivateOpsApi::Request::Whitelist class
      #
      def initialize
        super
      end

      # Submit Whitelist to token sale contract
      #
      # * Author: Aman
      # * Date: 25/10/2017
      # * Reviewed By:
      #
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def whitelist(token)
        send_request_of_type('post', '/token-sale/whitelist', {token: token})
      end

    end
  end
end

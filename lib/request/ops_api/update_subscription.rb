module Request
  module OpsApi

    class UpdateSubscription < Request::OpsApi::Base

      # Initialize
      #
      # * Author: Aniket
      # * Date: 04/09/2018
      # * Reviewed By:
      #
      # @return [Request::OpsApi::UpdateSubscription]
      #
      def initialize
        super
      end

      # Perform
      #
      # * Author: Aniket
      # * Date: 04/09/2018
      # * Reviewed By:
      #
      # @param [Array] contract_addresses (mandatory)
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def perform(params)
        send_request_of_type(GlobalConstant::PublicOpsApi.public_ops_api_type, 'post', '/subscribe/whitelist-updated', params)
      end

    end

  end

end
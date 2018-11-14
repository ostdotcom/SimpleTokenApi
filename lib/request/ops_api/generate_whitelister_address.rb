module Request
  module OpsApi

    class GenerateWhitelisterAddress < Request::OpsApi::Base

      # Initialize
      #
      # * Author: Tejas
      # * Date: 09/10/2018
      # * Reviewed By:
      #
      # @return [Request::OpsApi::GenerateWhitelisterAddress]
      #
      def initialize
        super
      end

      # Perform
      #
      # * Author: Tejas
      # * Date: 09/10/2018
      # * Reviewed By:
      #
      # @param [String] address (mandatory)
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def perform(params)
        send_request_of_type(GlobalConstant::PrivateOpsApi.private_ops_api_type,
                             'post',
                             '/address/generate-whitelister-address',
                             params)
      end

    end
  end
end

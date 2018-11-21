module Request
  module OpsApi

    class GetEthBalance < Request::OpsApi::Base

      # Initialize
      #
      # * Author: Kedar
      # * Date: 15/11/2017
      # * Reviewed By: Sunil
      #
      # @return [Request::OpsApi::GetEthBalance]
      #
      def initialize
        super
      end

      # Perform
      #
      # * Author: Kedar
      # * Date: 15/11/2017
      # * Reviewed By: Sunil
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

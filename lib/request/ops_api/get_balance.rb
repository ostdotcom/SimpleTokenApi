module Request
  module OpsApi

    class GetBalance < Request::OpsApi::Base

      # Initialize
      #
      # * Author: Kedar, Alpesh
      # * Date: 15/11/2017
      # * Reviewed By: Sunil
      #
      # @return [Request::OpsApi::GetBalance]
      #
      def initialize
        super
      end

      # Perform
      #
      # * Author: Kedar, Alpesh
      # * Date: 15/11/2017
      # * Reviewed By: Sunil
      #
      # @param [String] ethereum_address (mandatory)
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def perform(params)
        send_request_of_type(
          GlobalConstant::PublicOpsApi.public_ops_api_type, 'get', '/token-sale/get-balance', params
        )
      end

    end

  end

end

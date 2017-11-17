module OpsApi

  module Request

    class GetBalance < OpsApi::Request::Base

      # Initialize
      #
      # * Author: Kedar, Alpesh
      # * Date: 15/11/2017
      # * Reviewed By: Sunil
      #
      # @return [OpsApi::Request::GetBalance]
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

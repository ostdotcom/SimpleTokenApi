module OpsApi

  module Request

    class GetBlockInfo < OpsApi::Request::Base

      # Initialize
      #
      # * Author: Aman
      # * Date: 31/10/2017
      # * Reviewed By:
      #
      # @return [OpsApi::Request::GetBlockInfo]
      #
      def initialize
        super
      end

      # Perform
      #
      # * Author: Aman
      # * Date: 31/10/2017
      # * Reviewed By:
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def perform(params)
        send_request_of_type(GlobalConstant::PublicOpsApi.public_ops_api_type, 'get', '/block/get-info', params)
      end

    end
  end
end

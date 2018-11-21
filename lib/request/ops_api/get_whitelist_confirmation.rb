module Request
  module OpsApi

    class GetWhitelistConfirmation < Request::OpsApi::Base

      # Initialize
      #
      # * Author: Kedar
      # * Date: 26/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Request::OpsApi::GetWhitelistConfirmation]
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
      # @param [String] transaction_hash (mandatory)
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def perform(params)
        params.merge!({contract_type: GlobalConstant::PublicOpsApi.generic_whitelist_contract_type})
        send_request_of_type(GlobalConstant::PublicOpsApi.public_ops_api_type, 'get', '/transaction/get-info', params)
      end

    end
  end
end

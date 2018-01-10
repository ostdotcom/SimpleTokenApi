module OpsApi

  module Request

    class TransferEther < OpsApi::Request::Base

      # Initialize
      #
      # * Author: Aman
      # * Date: 08/01/2018
      # * Reviewed By:
      #
      # @return [OpsApi::Request::TransferEther]
      #
      def initialize
        super
      end

      # Transfer Ether to address
      #
      # * Author: Aman
      # * Date: 08/01/2018
      # * Reviewed By:
      #
      # @param [String] ethereum_address (mandatory)
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def transfer(params)
        send_request_of_type(GlobalConstant::PrivateOpsApi.private_ops_api_type, 'post', '/token-sale/transfer-ether', params)
      end

    end

  end

end

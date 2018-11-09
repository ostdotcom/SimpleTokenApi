module Request
  module OpsApi

    class Base < Request::Base


      # Initialize
      #
      # * Author: Aman
      # * Date: 25/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Request::OpsApi::Base]
      #
      def initialize
        super
      end

      private

      # Send Api request
      #
      # * Author: Aman
      # * Date: 25/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Result::Base] returns an object of Result::Base class
      #
      def send_request_of_type(ops_api_type, request_type, path, params)

        request_path = ((ops_api_type == GlobalConstant::PrivateOpsApi.private_ops_api_type) ?
                            GlobalConstant::PrivateOpsApi.base_url : GlobalConstant::PublicOpsApi.base_url) + path

        parameterized_token = {token: get_jwt_token(ops_api_type, params)}

        send_request(request_type, request_path, parameterized_token)

      end

      # Create encrypted Token for whitelisting parameter
      #
      # * Author: Abhay
      # * Date: 31/10/2017
      # * Reviewed By: Kedar
      #
      # @params [String] private ops/ public ops
      # @params [Hash] data
      #
      # @return [String] Encoded token
      #
      def get_jwt_token(ops_api_type, data)
        payload = {data: data}
        secret_key = (ops_api_type == GlobalConstant::PrivateOpsApi.private_ops_api_type) ?
                         GlobalConstant::PrivateOpsApi.secret_key :
                         GlobalConstant::PublicOpsApi.secret_key

        JWT.encode(payload, secret_key, 'HS256')
      end

    end
  end
end
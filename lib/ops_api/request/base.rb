module OpsApi

  module Request

    class Base

      include Util::ResultHelper

      require 'http'
      require 'openssl'

      # Initialize
      #
      # * Author: Aman
      # * Date: 25/10/2017
      # * Reviewed By: Sunil
      #
      # @return [OpsApi::Request::Base]
      #
      def initialize
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
        begin

          request_path = ((ops_api_type == GlobalConstant::PrivateOpsApi.private_ops_api_type) ?
              GlobalConstant::PrivateOpsApi.base_url : GlobalConstant::PublicOpsApi.base_url) + path

          # It overrides verification of SSL certificates
          ssl_context = OpenSSL::SSL::SSLContext.new
          ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE

          parameterized_token = {token: get_jwt_token(ops_api_type, params)}

          case request_type
            when 'get'
              response = HTTP.get(request_path, params: parameterized_token, ssl_context: ssl_context)
            when 'post'
              response = HTTP.post(request_path, json: parameterized_token, ssl_context: ssl_context)
            else
              return error_with_data('poa_r_b_1',
                                     "Request type not implemented: #{request_type}",
                                     'Something Went Wrong.',
                                     GlobalConstant::ErrorAction.default,
                                     {})
          end

          case response.status
            when 200
              parsed_response = Oj.load(response.body.to_s)
              if parsed_response['success']
                return success_with_data(HashWithIndifferentAccess.new(parsed_response['data']))
              else
                # web3_js_error = true is required because when API is down or any exception is raised or response is not 200
                # front end doesn't need to see invalid ethereum address
                return error_with_data(parsed_response['err']['code']+':st(poa_r_b_2)',
                                       "Error in API call: #{response.status} - #{parsed_response['err']['msg']}",
                                       'Something Went Wrong.',
                                       GlobalConstant::ErrorAction.default,
                                       {web3_js_error: true})
              end
            else
              return error_with_data('poa_r_b_3',
                                     "Error in API call: #{response.status}",
                                     'Something Went Wrong.',
                                     GlobalConstant::ErrorAction.default,
                                     {})
          end
        rescue => e
          return error_with_data('poa_r_b_4',
                                 "Exception in API call: #{e.message}",
                                 'Something Went Wrong.',
                                 GlobalConstant::ErrorAction.default,
                                 {})
        end
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
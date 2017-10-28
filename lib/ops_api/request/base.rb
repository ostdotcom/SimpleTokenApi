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

          case request_type
            when 'get'
              response = HTTP.get(request_path, params: params, ssl_context: ssl_context)
            when 'post'
              response = HTTP.post(request_path, json: params, ssl_context: ssl_context)
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
                return success_with_data(parsed_response['data'])
              else
                return error_with_data('poa_r_b_2',
                                       "Error in API call: #{response.status} - #{parsed_response['err']['msg']}",
                                       'Something Went Wrong.',
                                       GlobalConstant::ErrorAction.default,
                                       {})
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

    end
  end
end
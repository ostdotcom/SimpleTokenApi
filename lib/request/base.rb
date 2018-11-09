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
    # @return [Request::Base]
    #
    def initialize
      @timeouts = {write: 60, connect: 60, read: 60}
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
    def send_request(request_type, request_path, parameterized_token)
      begin

        # It overrides verification of SSL certificates
        ssl_context = OpenSSL::SSL::SSLContext.new
        ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE

        case request_type
          when 'get'
            response = HTTP.timeout(@timeouts)
                           .get(request_path, params: parameterized_token, ssl_context: ssl_context)
          when 'post'
            response = HTTP.timeout(@timeouts)
                           .post(request_path, json: parameterized_token, ssl_context: ssl_context)
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
                return error_with_data(parsed_response['err']['code'],
                                       "#{parsed_response['err']['msg']}",
                                       parsed_response['err']['msg'],
                                       GlobalConstant::ErrorAction.default,
                                       {})
              end
            when 401
              deprecated_error_with_internal_code('oka_r_unauthorized', 'ost kyc api authentication failed',
                                                  GlobalConstant::ErrorCode.ok, {}, {}, 'Invalid Credentials')

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
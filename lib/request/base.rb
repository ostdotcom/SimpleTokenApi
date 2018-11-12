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
            return error_with_internal_code('r_b_sr_3',
                                            "Request type not implemented: #{request_type}",
                                            GlobalConstant::ErrorCode.default,
                                            {}, [], 'Something Went Wrong.')

        end

        success_with_data({http_response: response})

      rescue Timeout::Error => e
        return error_with_internal_code('r_b_sr_1',
                                        'Api error: Request time Out Error',
                                        GlobalConstant::ErrorCode.unprocessable_entity,
                                        {}, [], 'Time Out Error')

      rescue Exception => e
        exception_with_internal_code(e, 'r_b_sr_2',
                                     'Something Went Wrong',
                                     GlobalConstant::ErrorCode.unhandled_exception)
      end


    end

  end
end
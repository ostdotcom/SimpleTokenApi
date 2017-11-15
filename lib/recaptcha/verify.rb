module Recaptcha

  class Verify

    require 'http'

    include Util::ResultHelper

    # Initialize
    #
    # * Author: Sunil Khedar
    # * Date: 10/10/2017
    # * Reviewed By: Sunil
    #
    # @params [String] response (mandatory) - g-recaptcha-response received
    # @params [String] remoteip (mandatory) - Customer remoteip
    #
    # @return [Recaptcha::Verify]
    #
    def initialize(params)
      Rails.logger.info("--- Recaptcha::Verify params: #{params}")
      @params = params.merge!(:secret => GlobalConstant::Base.recaptcha['secret_key'])
    end

    # Perform
    #
    # * Author: Sunil Khedar
    # * Date: 10/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def perform
      r = send_request_of_type
      Rails.logger.info("--- Recaptcha::Verify response: #{r.inspect}")
      return r
    end

    private

    # Send request
    #
    # * Author: Sunil Khedar
    # * Date: 10/10/2017
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def send_request_of_type
      begin
        request_path = 'https://www.google.com/recaptcha/api/siteverify'
        response = HTTP.put(request_path, :form => @params)
        case response.status
          when 200
            parsed_response = Oj.load(response.body.to_s)
            if parsed_response['success']
              return success_with_data(response: parsed_response)
            else
              return error_with_data('rv_1',
                                     "Error in API call: #{parsed_response}",
                                     'Recaptcha validation failed.',
                                     GlobalConstant::ErrorAction.default,
                                     parsed_response)
            end
          else
            return error_with_data('rv_2',
                                              "Error in API call: #{response.status}",
                                              'Recaptcha validation failed.',
                                              GlobalConstant::ErrorAction.default,
                                              {})
        end
      rescue => e
        return error_with_data('rv_3',
                                          "Exception in API call: #{e.message}",
                                          'Recaptcha validation has failed.',
                                          GlobalConstant::ErrorAction.default,
                                          {})
      end
    end

  end

end
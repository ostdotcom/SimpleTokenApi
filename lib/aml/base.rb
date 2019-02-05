module Aml

  class Base

    require 'http'

    include Util::ResultHelperinclude Util::ResultHelper

    # Initialize
    #
    # * Author: Mayur Patil
    # * Date: 8/1/2019
    # * Reviewed By:
    #
    # @params [Hash]
    # @return [Aml::Base]
    #
    def initialize
    end

    # GET request
    #
    # * Author: Mayur Patil
    # * Date: 9/1/2019
    # * Reviewed By:
    #
    # @param [String] path - request path
    # @param [Hash] params - request params
    #
    # @return [Result::Base]
    #
    def get_request(path, params = {}, options={})
      r = HttpHelper::HttpRequest.new(get_params(path, params)).get
      parse_api_response(r, options)
    end

    # POST request
    #
    # * Author: Mayur Patil
    # * Date: 9/1/2019
    # * Reviewed By:
    #
    # @param [String] path - request path
    # @param [Hash] params - request params
    #
    # @return [Result::Base]
    #
    def post_request(path, params = {}, options={})
      r = HttpHelper::HttpRequest.new(get_params(path, params)).post
      parse_api_response(r, options)
    end

    private

    # Params required for request
    #
    # * Author: Mayur Patil
    # * Date: 9/1/2019
    # * Reviewed By:
    #
    # @param [String] path - request path
    # @param [Hash] params - request params
    #
    # @return [Hash]
    #
    def get_params(path, params)
      {
          url: base_url + path,
          request_parameters: params,
          options: get_aml_request_options
      }
    end

    # header for requesting AML resource
    #
    # * Author: Mayur Patil
    # * Date: 9/1/2019
    # * Reviewed By:
    #
    # @param [String] path - request path
    # @param [Hash] params - request params
    #
    # @return [Hash]
    #
    def get_aml_request_options
       {headers: { CaseSensitiveString.new('apiKey') => GlobalConstant::Base.aml_config[:search][:api_key] },
       timeout: 25
       }
    end


    # parses api response
    #
    # * Author: Mayur Patil
    # * Date: 9/1/2019
    # * Reviewed By:
    #
    # @param [Result::Base] r
    # @param [Hash] options - optional config for parsing
    #
    # @return [Result::Base]
    #

    def parse_api_response(r, options={})
      return r unless r.success?

      http_response = r.data[:http_response]

      # Note: For get Pdf api the response is a string and therefore no JSON parse and only for success case
      if (options[:has_string_response] == true) && (http_response.class.name == 'Net::HTTPOK')
        response_data = http_response.body
      else
        response_data = Oj.load(http_response.body, mode: :strict)
      end

      case http_response.class.name
        when 'Net::HTTPOK'
        response_data = response_data.deep_symbolize_keys if Util::CommonValidateAndSanitize.is_hash?(response_data)
        success_result({aml_response: response_data})
      when 'Net::HTTPBadRequest'
        # 400
        error_with_internal_code('c_ab_par_1',
                                 'ost kyc aml error',
                                 GlobalConstant::ErrorCode.invalid_request_parameters,
                                 response_data, [], response_data['message']
        )

      when 'Net::HTTPUnprocessableEntity'
        # 422
        error_with_internal_code('c_ab_par_2',
                                 'ost kyc aml error',
                                 GlobalConstant::ErrorCode.unprocessable_entity,
                                 response_data, [], response_data['message']
        )
      when "Net::HTTPUnauthorized"
        # 401
        error_with_internal_code('c_ab_par_3',
                                 'ost kyc aml authentication failed',
                                 GlobalConstant::ErrorCode.unauthorized_access,
                                 response_data, [], response_data['message']
        )

      when "Net::HTTPBadGateway"
        #500
        error_with_internal_code('c_ab_par_4',
                                 'ost kyc aml bad gateway',
                                 GlobalConstant::ErrorCode.unhandled_exception,
                                 response_data, [], response_data['message']
        )
      when "Net::HTTPInternalServerError"
        error_with_internal_code('c_ab_par_5',
                                 'ost kyc aml bad internal server error',
                                 GlobalConstant::ErrorCode.unhandled_exception,
                                 response_data, [], response_data['message']
        )
      when "Net::HTTPForbidden"
        #403
        error_with_internal_code('c_ab_par_6',
                                 'ost kyc aml forbidden',
                                 GlobalConstant::ErrorCode.forbidden,
                                 response_data, [], response_data['message']
        )
        when "Net::HTTPNotFound"
          #404
          error_with_internal_code('c_ab_par_7',
                                   'ost kyc aml not_found',
                                   GlobalConstant::ErrorCode.not_found,
                                   response_data, [], response_data['message']
          )
      else
        # HTTP error status code (500, 504...)
        error_with_internal_code('c_ab_par_8',
                                 "ost kyc aml STATUS CODE #{http_response.code.to_i}",
                                 GlobalConstant::ErrorCode.unhandled_exception,
                                 response_data, [], 'ost kyc aml exception'
        )
      end
    end

    # get base url
    #
    # * Author: mayur
    # * Date: 8/1/2019
    # * Reviewed By:
    #
    #
    #
    # @return [String]
    #
    def base_url
     fail 'base_url not implemented'
    end

  end
end
module Aml

  class Base

    require 'http'

    include Util::ResultHelper

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
    def get_request(path, params = {})

      r = HttpHelper::HttpRequest.new(get_params(path, params)).get

      parse_api_response(r)

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
    def post_request(path, params = {})
      r = HttpHelper::HttpRequest.new(get_params(path, params)).post

      parse_api_response(r)

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
          url: path,
          request_parameters: params,
          options: get_aml_request_header
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
    def get_aml_request_header
       {headers: { CaseSensitiveString.new('apiKey') => GlobalConstant::Base.aml_config[:search][:api_key] }}
    end


    # parses api response
    #
    # * Author: Mayur Patil
    # * Date: 9/1/2019
    # * Reviewed By:
    #
    # @param [Result::Base] r
    #
    # @return [Result::Base]
    #

    def parse_api_response(r)

      return r unless r.success?

      http_response = r.data[:http_response]

      response_data = Oj.load(http_response.body, mode: :strict) rescue http_response.body

      Rails.logger.info("=*=HTTP-Response*= #{response_data.inspect}")

      case http_response.class.name
      when 'Net::HTTPOK'
        response_data = response_data.deep_symbolize_keys if Util::CommonValidateAndSanitize.is_hash?(data)
        success_result({aml_response: response_data})
      when 'Net::HTTPBadRequest'
        # 400
        error_with_internal_code('c_ab_par_1',
                                 'ost kyc aml error',
                                 GlobalConstant::ErrorCode.invalid_request_parameters,
                                 {}, {}, ''
        )

      when 'Net::HTTPUnprocessableEntity'
        # 422
        error_with_internal_code('c_ab_par_2',
                                 'ost kyc aml error',
                                 GlobalConstant::ErrorCode.unprocessable_entity,
                                 {}, {}, ''
        )
      when "Net::HTTPUnauthorized"
        # 401
        error_with_internal_code('c_ab_par_3',
                                 'ost kyc aml authentication failed',
                                 GlobalConstant::ErrorCode.unauthorized_access,
                                 http_response, {}, ''
        )

      when "Net::HTTPBadGateway"
        #500
        error_with_internal_code('c_ab_par_4',
                                 'ost kyc aml bad gateway',
                                 GlobalConstant::ErrorCode.unhandled_exception,
                                 {}, {}, ''
        )
      when "Net::HTTPInternalServerError"
        error_with_internal_code('c_ab_par_5',
                                 'ost kyc aml bad internal server error',
                                 GlobalConstant::ErrorCode.unhandled_exception,
                                 {}, {}, ''
        )
      when "Net::HTTPForbidden"
        #403
        error_with_internal_code('c_ab_par_6',
                                 'ost kyc aml forbidden',
                                 GlobalConstant::ErrorCode.forbidden,
                                 {}, {}, ''
        )
      else
        # HTTP error status code (500, 504...)
        error_with_internal_code('c_ab_par_7',
                                 "ost kyc aml STATUS CODE #{http_response.code.to_i}",
                                 GlobalConstant::ErrorCode.unhandled_exception,
                                 {}, {}, 'ost kyc aml exception'
        )
      end
    end



  end
end
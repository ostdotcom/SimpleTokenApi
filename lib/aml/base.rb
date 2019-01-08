module Aml

  class Base

    require 'http'

    include Util::ResultHelper

    # Initialize
    #
    # * Author: Sunil Khedar
    # * Date: 10/10/2017
    # * Reviewed By:
    #
    # @params [Integer] client id (mandatory) - Client id
    # @return [Aml::Base]
    #
    def initialize(params)

    end

    private

    # GET request
    #
    # * Author: Sunil Khedar
    # * Date: 10/10/2017
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
    # * Author: Sunil Khedar
    # * Date: 10/10/2017
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




    def get_params(path, params)
      {
          url: path,
          request_parameters: params,
          options: get_aml_request_header
      }
    end

    def get_aml_request_header
       {headers: { CaseSensitiveString.new('apiKey') => GlobalConstant::Base.aml_config[:search][:api_key] }}
    end



    def parse_api_response(r)

      return r unless r.success?

      http_response = r.data[:http_response]

      response_data = Oj.load(http_response.body, mode: :strict) rescue http_response.body

      Rails.logger.info("=*=HTTP-Response*= #{response_data.inspect}")
      puts "http_response.class.name : #{http_response.class.name}"

      case http_response.class.name
      when 'Net::HTTPOK'
        success_result({aml_response: response_data})
      when 'Net::HTTPBadRequest'
        # 400
        error_with_internal_code('c_whp_par_1',
                                 'ost kyc webhook error',
                                 GlobalConstant::ErrorCode.invalid_request_parameters,
                                 {}, {}, ''
        )

      when 'Net::HTTPUnprocessableEntity'
        # 422
        error_with_internal_code('c_whp_par_2',
                                 'ost kyc webhook error',
                                 GlobalConstant::ErrorCode.unprocessable_entity,
                                 {}, {}, ''
        )
      when "Net::HTTPUnauthorized"
        # 401
        error_with_internal_code('c_whp_par_3',
                                 'ost kyc webhook authentication failed',
                                 GlobalConstant::ErrorCode.unauthorized_access,
                                 {}, {}, ''
        )

      when "Net::HTTPBadGateway"
        #500
        error_with_internal_code('c_whp_par_4',
                                 'ost kyc webhook bad gateway',
                                 GlobalConstant::ErrorCode.unhandled_exception,
                                 {}, {}, ''
        )
      when "Net::HTTPInternalServerError"
        error_with_internal_code('c_whp_par_5',
                                 'ost kyc webhook bad internal server error',
                                 GlobalConstant::ErrorCode.unhandled_exception,
                                 {}, {}, ''
        )
      when "Net::HTTPForbidden"
        #403
        error_with_internal_code('c_whp_par_6',
                                 'ost kyc webhook forbidden',
                                 GlobalConstant::ErrorCode.forbidden,
                                 {}, {}, ''
        )
      else
        # HTTP error status code (500, 504...)
        error_with_internal_code('c_whp_par_7',
                                 "ost kyc webhook STATUS CODE #{http_response.code.to_i}",
                                 GlobalConstant::ErrorCode.unhandled_exception,
                                 {}, {}, 'ost kyc webhook exception'
        )
      end
    end



  end
end
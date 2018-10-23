module OstKycApi
  class RequestV2

    require "uri"
    require "open-uri"
    require "openssl"
    require 'net/http'

    include Util::ResultHelper

    # Initialize
    # @params [String] api_key(mandatory)
    # @params [String] api_secret(mandatory)
    # @params [String] environment(mandatory)
    #
    # Sets @api_base_url, @version
    #
    # @return [OstKycApi::Request]
    #
    def initialize(params)
      @params = params
      @api_key = @params[:api_key]
      @api_secret = @params[:api_secret]
      @environment = @params[:environment] || 'development'

      @api_base_url = api_base_url(@environment)

      @version = 'v2'
    end

    # get api base url
    #
    # * Author: Tejas
    # * Date: 17/08/2018
    # * Reviewed By:
    #
    # @return @api_base_url
    #
    def api_base_url(environment)
      GlobalConstant::KycApiBaseDomain.get_base_domain_url_for_environment(environment)
    end

    # create user
    #
    # * Author: Aniket
    # * Date: 21/09/2018
    # * Reviewed By:
    #
    # @params [String] user_id (mandatory)
    # @params [Hash] custom_params (mandatory) - email
    #
    def create_user(custom_params = {})
      endpoint = "/api/#{@version}/users"
      params = request_parameters(endpoint, custom_params)
      post(params)
    end

    # get user
    #
    # * Author: Aniket
    # * Date: 21/09/2018
    # * Reviewed By:
    #
    # @params [String] user_id (mandatory)
    # @params [Hash] custom_params (optional)
    #
    def get_user(user_id, custom_params = {})
      endpoint = "/api/#{@version}/users/#{user_id}"
      params = request_parameters(endpoint, custom_params)
      get(params)
    end

    # get user list
    #
    # * Author: Aniket
    # * Date: 21/09/2018
    # * Reviewed By:
    #
    # @params [String] user_id (mandatory)
    # @params [Hash] custom_params (optional) - filters, page_size, page_number, order
    #
    def get_user_list(custom_params = nil)
      default_params = {page_number: 1, order: 'asc', filters: {}, page_size: 3}
      endpoint = "/api/#{@version}/users"

      custom_params = custom_params || default_params
      params = request_parameters(endpoint, custom_params)
      get(params)
    end

    # submit kyc
    #
    # * Author: Aniket
    # * Date: 26/09/2018
    # * Reviewed By:
    #
    # @params [Hash] custom_params (mandatory) - first_name, last_name, birthdate, country, nationality, document_id_number,
    # document_id_file, selfie_file, residence_proof_file,investor_proof_files, ethereum_address, postal_code, street_address,
    # city, state
    #
    def submit_kyc(user_id, custom_params = nil)
      default_params = {}

      endpoint = "/api/#{@version}/users-kyc/#{user_id}"

      custom_params = custom_params || default_params
      params = request_parameters(endpoint, custom_params)
      post(params)
    end

    # Get user kyc for particular id
    #
    # * Author: Tejas
    # * Date: 27/09/2018
    # * Reviewed By:
    #
    # @params [Integer] id (mandatory) - user id
    #
    def get_user_kyc(id)
      endpoint = "/api/#{@version}/users-kyc/#{id}"

      params = request_parameters(endpoint)
      get(params)
    end

    # verify ethereum address
    #
    # * Author: Aniket
    # * Date: 26/09/2018
    # * Reviewed By:
    #
    # @params [Hash] custom_params (mandatory) - filters, order, page_number, page_size
    #
    def get_users_kyc_list(custom_params = nil)
      default_params = {filter: {admin_status: 'all', aml_status: 'all'}}

      endpoint = "/api/#{@version}/users-kyc"

      custom_params = custom_params || default_params
      params = request_parameters(endpoint, custom_params)
      get(params)
    end


    # Get user kyc details for particular id
    #
    # * Author: Tejas
    # * Date: 27/09/2018
    # * Reviewed By:
    #
    # @params [Integer] id (mandatory) - user id
    #
    def get_user_kyc_detail(id)
      endpoint = "/api/#{@version}/users-kyc-detail/#{id}"

      params = request_parameters(endpoint)
      get(params)
    end

    # get pre signed url for put
    #
    # * Author: Aniket
    # * Date: 26/09/2018
    # * Reviewed By:
    #
    # @params [String] user_id (mandatory)
    # @params [Hash] custom_params (optional) - images, pdfs
    #
    def get_presigned_url_put(custom_params = nil)

      default_val = {
          files: {
              selfie: 'image/jpeg'
          }
      }
      endpoint = "/api/#{@version}/users-kyc/pre-signed-urls/for-put"

      custom_params = custom_params || default_val
      params = request_parameters(endpoint, custom_params)
      get(params)
    end

    # get pre signed url for post
    #
    # * Author: Aniket
    # * Date: 26/09/2018
    # * Reviewed By:
    #
    # @params [String] user_id (mandatory)
    # @params [Hash] custom_params (optional) - images, pdfs
    #
    def get_presigned_url_post(custom_params = nil)

      default_val = {
          files: {
              residence_proof: 'application/pdf',
              investor_proof_file1: 'application/pdf',
              investor_proof_file2: 'application/pdf',
              document_id: 'image/jpeg',
              selfie: 'image/jpeg'
          }
      }
      endpoint = "/api/#{@version}/users-kyc/pre-signed-urls/for-post"

      custom_params = custom_params || default_val
      params = request_parameters(endpoint, custom_params)
      get(params)
    end

    # verify ethereum address
    #
    # * Author: Aniket
    # * Date: 26/09/2018
    # * Reviewed By:
    # 
    #
    # @params [Hash] custom_params (mandatory) - ethereum_address
    #
    def verify_ethereum_address(custom_params = {})
      endpoint = "/api/#{@version}/ethereum-address-validation"
      params = request_parameters(endpoint, custom_params)
      get(params)
    end

    ########################################################################################################################
    private

    def get (params)
      r = HttpHelper::HttpRequest.new(params).get
      return r unless r.success?

      parse_api_response(r.data[:http_response])
    end

    def post (params)
      r = HttpHelper::HttpRequest.new(params).post
      return r unless r.success?

      parse_api_response(r.data[:http_response])
    end

    # Get request parametrs for the api call.
    #
    # params:
    #   uri, URI object
    #
    # returns [Hash] url and requesat parameters are sent
    #
    def request_parameters(endpoint, custom_params={})
      custom_params.merge!("request_timestamp" => Time.now.to_i, "api_key" => @api_key)
      signature_params = {
          url: endpoint,
          api_secret: @api_secret,
          request_parameters: custom_params.dup
      }
      signature = HttpHelper::SignatureGenerator.new(signature_params).perform
      custom_params.merge!(signature: signature)
      {
          url: @api_base_url + endpoint,
          request_parameters: custom_params
      }
    end


    # Parse API response
    #
    # * Author: Aniket
    # * Date: 15/10/2018
    # * Reviewed By:
    #
    # @return [Result::Base] returns an object of Result::Base class
    #
    def parse_api_response(http_response)
      response_data = Oj.load(http_response.body, mode: :strict) rescue {}

      Rails.logger.info("=*=HTTP-Response*= #{response_data.inspect}")
      puts "http_response.class.name : #{http_response.class.name}"

      case http_response.class.name
        when 'Net::HTTPOK'
          success_result(response_data['data'])
        when 'Net::HTTPBadRequest'
          # 400
          error_with_internal_code('h_hh_par_1',
                                   'ost kyc api error',
                                   GlobalConstant::ErrorCode.invalid_request_parameters,
                                   response_data['data'],
                                   response_data['err']['error_data'],
                                   response_data['err']['msg']
          )

        when 'Net::HTTPUnprocessableEntity'
          # 422
          error_with_internal_code('h_hh_par_2',
                                   'ost kyc api error',
                                   GlobalConstant::ErrorCode.unprocessable_entity,
                                   response_data['data'],
                                   response_data['err']['error_data'],
                                   response_data['err']['msg']
          )
        when "Net::HTTPUnauthorized"
          # 401
          error_with_internal_code('h_hh_par_3',
                                   'ost kyc api authentication failed',
                                   GlobalConstant::ErrorCode.unauthorized_access,
                                   {}, {},
                                   response_data['err']['msg']
          )

        when "Net::HTTPBadGateway"
          #500
          error_with_internal_code('h_hh_par_4',
                                   'ost kyc api bad gateway',
                                   GlobalConstant::ErrorCode.unhandled_exception,
                                   {},{}, ''
          )
        when "Net::HTTPInternalServerError"
          error_with_internal_code('h_hh_par_5',
                                   'ost kyc api bad internal server error',
                                   GlobalConstant::ErrorCode.unhandled_exception,
                                   {},{},''
          )
        when "Net::HTTPForbidden"
          #403
          error_with_internal_code('h_hh_par_6',
                                   'ost kyc api forbidden',
                                   GlobalConstant::ErrorCode.forbidden,
                                   {},{},response_data['err']['msg']
          )
        else
          # HTTP error status code (500, 504...)
          exception_with_internal_code(Exception.new("Ost Kyc API STATUS CODE #{http_response.code.to_i}"),
                                       'ost_kyc_api_exception',
                                       'ost kyc api exception',
                                       GlobalConstant::ErrorCode.unhandled_exception)
      end
    end
  end
end

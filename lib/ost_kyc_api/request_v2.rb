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
      make_post_request(endpoint, custom_params)
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
      make_get_request(endpoint, custom_params)
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
      make_get_request(endpoint, custom_params)
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
    def submit_kyc(user_id,custom_params= nil)
      default_params = {}

      endpoint = "/api/#{@version}/users-kyc/#{user_id}"
      custom_params = custom_params || default_params
      make_post_request(endpoint, custom_params)
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
      make_get_request(endpoint)
    end

    # verify ethereum address
    #
    # * Author: Aniket
    # * Date: 26/09/2018
    # * Reviewed By:
    #
    # @params [Hash] custom_params (mandatory) - filters, order, page_number, page_size
    #
    def get_users_kyc_list(custom_params= nil)
      default_params = {filter:{admin_status:'all' ,aml_status:'all'}}

      endpoint = "/api/#{@version}/users-kyc"
      custom_params = custom_params || default_params
      make_get_request(endpoint, custom_params)
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
      endpoint = "/api/#{@version}/users-kyc-details/#{id}"
      make_get_request(endpoint)
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
              residence_proof: 'application/pdf',
              investor_proof_file1: 'application/pdf',
              investor_proof_file2: 'application/pdf',
              document_id: 'image/jpeg',
              selfie: 'image/jpeg'
          }
      }
      endpoint = "/api/#{@version}/users-kyc/pre-signed-urls/for-put"

      custom_params = custom_params || default_val
      make_get_request(endpoint, custom_params)
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
      make_get_request(endpoint, custom_params)
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
    def verify_ethereum_address(custom_params = nil)
      endpoint = "/api/#{@version}/ethereum-address-validation"
      make_get_request(endpoint, custom_params)
    end

    ########################################################################################################################
    private

    # Create Request Data
    #
    # params:
    #   uri, URI object
    #
    # returns:
    #   http, Net::HTTP object
    #
    def setup_request(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme == "https"
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end
      http
    end

    # Create Base Params
    #
    # params:
    #   endpoint, String
    #   custom_params, Hash
    #
    # returns:
    #   Hash, Request Data
    #
    def base_params(endpoint, custom_params = {})
      request_time = Time.now.to_i
      request_params = custom_params.merge("request_timestamp" => request_time, "api_key" => @api_key)
      query_param = request_params.to_query.gsub(/^&/, '')
      str = "#{endpoint}?#{query_param}"
      signature = generate_signature(str)
      request_params.merge!("signature" => signature)
      request_params
    end

    # Generate Signature
    #
    # params:
    #   string_to_sign, String
    #
    # returns:
    #   String, HexDigest
    #
    def generate_signature(string_to_sign)
      digest = OpenSSL::Digest.new('sha256')
      Rails.logger.info("--------string_to_sign=>#{string_to_sign}-----")
      OpenSSL::HMAC.hexdigest(digest, @api_secret, string_to_sign)
    end

    # Post API URI object
    #
    # params:
    #   endpoint, String
    #
    # returns:
    #   Object, URI object
    #
    def post_api_uri(endpoint)
      URI(@api_base_url + endpoint)
    end

    # Get API Url
    #
    # params:
    #   endpoint, String
    #
    # returns:
    #   String
    #
    def get_api_uri(endpoint, params = {})
      req_params = params.present? ? "?#{params.to_query}" : ""
      URI.parse(@api_base_url + endpoint + req_params)
    end

    # Make Get Request
    #
    # params:
    #   endpoint, String
    #   custom_params, Hash
    #
    # returns:
    #   Hash, Response
    #
    def make_get_request(endpoint, custom_params = {})
      request_params = base_params(endpoint, custom_params)
      uri = get_api_uri(endpoint, request_params)

      result = handle_with_exception(uri) do |http|
        http.get(uri)
      end

      result
    end

    # Make Post Request
    #
    # params:
    #   endpoint, String
    #   custom_params, Hash
    #
    # returns:
    #   Hash, Response
    #
    def make_post_request(endpoint, custom_params = {})
      request_params = base_params(endpoint, custom_params)
      uri = post_api_uri(endpoint)

      result = handle_with_exception(uri) do |http|
        http.post(uri.path, request_params.to_query)
      end

      result
    end

    # Handle With Exception
    #
    # returns [Result::Base]
    #
    def handle_with_exception(uri)
      begin
        Timeout.timeout(GlobalConstant::PepoCampaigns.api_timeout) do
          http = setup_request(uri)
          result = yield(http)
          parse_api_response(result)
        end
      rescue Timeout::Error => e
        return deprecated_error_with_internal_code(e.message,
                                                   'simple token api error: Time Out Error', GlobalConstant::ErrorCode.ok,
                                                   {}, {}, 'Time Out Error')

      rescue Exception => e
        exception_with_internal_code(e, 'oka_r_hwe_1', 'Something Went Wrong', GlobalConstant::ErrorCode.ok)
      end
    end

    # Parse API response
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base] returns an object of Result::Base class
    #
    def parse_api_response(http_response)
      response_data = Oj.load(http_response.body, mode: :strict) rescue {}

      return response_data


      Rails.logger.info("=*=Simple-Token-API-ERROR=*= #{response_data.inspect}")
      puts "http_response.class.name : #{http_response.class.name}"
      case http_response.class.name
        when 'Net::HTTPOK'
          success_result(response_data['data'])
        when 'Net::HTTPBadRequest'
          # 400
          error_with_internal_code('l_oka_rv2_par_1',
                                   'ost kyc api error',
                                   GlobalConstant::ErrorCode.invalid_request_parameters,
                                   response_data['data'],
                                   response_data['err']['error_data'],
                                   response_data['err']['msg']
          )

        when 'Net::HTTPUnprocessableEntity'
          # 422
          error_with_internal_code('l_oka_rv2_par_1',
                                   'ost kyc api error',
                                   GlobalConstant::ErrorCode.unprocessable_entity,
                                   response_data['data'],
                                   response_data['err']['error_data'],
                                   response_data['err']['msg']
          )
        when "Net::HTTPUnauthorized"
          # 401
          deprecated_error_with_internal_code('oka_r_unauthorized', 'ost kyc api authentication failed',
                                              GlobalConstant::ErrorCode.ok, {}, {}, 'Invalid Credentials')
        else
          # HTTP error status code (500, 504...)
          exception_with_internal_code(Exception.new("Ost Kyc API STATUS CODE #{http_response.code.to_i}"), 'ost_kyc_api_exception', 'ost kyc api exception',
                                       GlobalConstant::ErrorCode.ok)
      end
    end

  end
end

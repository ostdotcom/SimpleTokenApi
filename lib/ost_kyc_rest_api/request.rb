module OstKycRestApi

  class Request #

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
    # @return [OstKycRestApi::Request]
    #
    def initialize(params)
      @params = params
      @api_key = @params[:api_key]
      @api_secret = @params[:api_secret]
      @environment = @params[:environment]

      @api_base_url = api_base_url(@environment)

      @version = 'v1'
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

    # Add Contact to a List
    #
    # params:
    #   list_id, Integer
    #   email, String
    #   attributes, Hash
    #   user_status, Hash
    #
    # returns:
    #   Hash, response data from server
    #
    def add_contact(email, kyc_data = {})
      custom_params = {
          "email" => email,
          "first_name" => kyc_data[:first_name] || 'aman',
          "last_name" => kyc_data[:last_name] || 'barbaria',
          "birthdate" => kyc_data[:birthdate] || '23/07/1991',
          "street_address" => kyc_data[:street_address] || 'magarpatta city',
          "city" => kyc_data[:city] || 'pune',
          "state" => kyc_data[:state] || 'maharashtra',
          "country" => kyc_data[:country] || 'INDIA',
          "postal_code" => kyc_data[:postal_code] || '411028',
          "ethereum_address" => kyc_data[:ethereum_address] || '0x2755a475Ff253Ae5BBE6C1c140f975e5e85534bD',
          "document_id_number" => kyc_data[:document_id_number] || "#{Time.now.to_i}",
          "nationality" => kyc_data[:nationality] || 'INDIAN',
          "document_id_file_path" => kyc_data[:document_id_file_path] || '2/i/687eb50ecbe60c37400746a59200c75b',
          "selfie_file_path" => kyc_data[:selfie_file_path] || '2/i/24d828f00557817e846ebed6109c0ac8',
          "residence_proof_file_path" => kyc_data[:residence_proof_file_path] || '3/i/d3817395b85581eab3068cb43f9c0f63',
          "investor_proof_files_path" => kyc_data[:investor_proof_files_path] ||
              ['3/i/d3817395b85581eab3068cb43f9c0f63', '3/i/d3817395b85581eab3068cb43f9c0f63'],
          "user_ip_address" => kyc_data[:user_ip_address]
      }
      endpoint = "/api/#{@version}/kyc/add-kyc/"
      params = request_parameters(endpoint, custom_params)
      post(params)
    end

    # Check if valid ethereum address
    #
    # @params [String] ethereum_address(mandatory)
    #
    def check_ethereum_address(ethereum_address)
      custom_params = {
          "ethereum_address" => ethereum_address
      }
      endpoint = "/api/#{@version}/kyc/check-ethereum-address/"
      params = request_parameters(endpoint, custom_params)
      get(params)
    end

    # Get upload Params for file upload
    #
    # @params [Hash] hash of image and pdf files content type data (mandatory)
    #
    def get_upload_params(custom_params = {})

      default_params = {
          "images" => {
              "file1.png" => 'image/png',
              "file2.jpg" => 'image/jpg'
          },
          "pdfs" => {
              "file3.pdf" => "application/pdf"
          }
      }
      custom_params = default_params if custom_params.blank?

      endpoint = "/api/#{@version}/kyc/upload-params/"
      params = request_parameters(endpoint, custom_params)
      get(params)
    end

    # Get details of a user
    #
    # @params [Integer] user_id
    # @params [String] email
    #
    def get_user_detail(user_id)
      endpoint = "/api/#{@version}/kyc/get-detail/"
      params = request_parameters(endpoint, {user_id: user_id})
      get(params)
    end

    # Get S3 urls for file upload
    #
    # @params [Hash] hash of image and pdf files content type data (mandatory)
    #
    def get_files_upload_urls(custom_params = {})

      default_params = {
          "images" => {
              "file1.png" => 'image/png',
              "file2.jpg" => 'image/jpg'
          },
          "pdfs" => {
              "file3.pdf" => "application/pdf"
          }
      }
      custom_params = default_params if custom_params.blank?

      endpoint = "/api/#{@version}/kyc/get-file-upload-urls/"
      params = request_parameters(endpoint, custom_params)
      get(params)
    end

    ##################################################################################################################
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
      custom_params.merge!("request_time" => Time.now.to_i, "api_key" => @api_key)
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
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base] returns an object of Result::Base class
    #
    def parse_api_response(http_response)
      response_data = Oj.load(http_response.body, mode: :strict) rescue {}

      # Rails.logger.info("=*=HTTPResponse=*= #{response_data.inspect}")

      case http_response.class.name
        when 'Net::HTTPOK'
          if response_data['success']
            # Success
            success_result(response_data['data'])
          else
            # API Error
            deprecated_error_with_internal_code(response_data['err']['code'],
                                                'simple token api error',
                                                GlobalConstant::ErrorCode.ok,
                                                {}, response_data['err']['error_data'],
                                                response_data['err']['display_text'])
          end
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

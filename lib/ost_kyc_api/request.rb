module OstKycApi

  class Request #

    require "uri"
    require "open-uri"
    require "openssl"

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
          "birthdate" => kyc_data[:birthdate] || '23/07/2091',
          "street_address" => kyc_data[:street_address] || 'magarpatta city',
          "city" => kyc_data[:city] || 'pune',
          "state" => kyc_data[:state] || 'maharashtra',
          "country" => kyc_data[:country] || 'INDIA',
          "postal_code" => kyc_data[:postal_code] || '411028',
          "ethereum_address" => kyc_data[:ethereum_address] || '0x2755a475Ff253Ae5BBE6C1c140f975e5e85534bD',
          "document_id_number" => kyc_data[:document_id_number] || "#{Time.now.to_i}",
          "nationality" => kyc_data[:nationality] || 'INDIAN',
          "document_id_file_path" => kyc_data[:document_id_file_path] || '/q/qw',
          "selfie_file_path" => kyc_data[:selfie_file_path] || 'w/er/',
          "residence_proof_file_path" => kyc_data[:residence_proof_file_path],
          "user_ip_address" => kyc_data[:user_ip_address]
      }
      endpoint = "/api/#{@version}/kyc/add-kyc/"
      make_post_request(endpoint, custom_params)
    end

    # Get Published Draft
    # * Author: Tejas
    # * Date: 17/08/2018
    # * Reviewed By:
    #
    #
    def get_published_draft
      endpoint = "/api/#{@version}/setting/configurator/get-published-draft/"
      make_get_request(endpoint)
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
      make_get_request(endpoint, custom_params)
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
      make_get_request(endpoint, custom_params)
    end

    # Get details of a user
    #
    # @params [Integer] user_id
    # @params [String] email
    #
    def get_user_detail(user_id)
      endpoint = "/api/#{@version}/kyc/get-detail/"
      make_get_request(endpoint, {user_id: user_id})
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
      make_get_request(endpoint, custom_params)
    end

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
      request_params = custom_params.merge("request_time" => request_time, "api_key" => @api_key)
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
    def get_api_url(endpoint)
      @api_base_url + endpoint
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
      raw_url = get_api_url(endpoint) + "?#{request_params.to_query}"

      result = handle_with_exception do
        response = URI.parse(raw_url).read
        parse_api_response(response)
      end

      return result
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

      result = handle_with_exception do
        http = setup_request(uri)
        result = http.post(uri.path, request_params.to_query)
        parse_api_response(result.body)
      end

      return result

    end

    # Handle With Exception
    #
    # returns [Result::Base]
    #
    def handle_with_exception
      begin
        Timeout.timeout(GlobalConstant::PepoCampaigns.api_timeout) do
          yield
        end
      rescue OpenURI::HTTPError => e
        if e.to_s == '401 Unauthorized'
          return error_with_internal_code(e.message, 'simple token api error', GlobalConstant::ErrorCode.ok,
                                          {}, {}, 'Invalid Credentials')
        end
        return error_with_internal_code(e.message,
                                        'simple token api error: SWR', GlobalConstant::ErrorCode.ok,
                                        {}, {}, 'Something Went Wrong')
      rescue Timeout::Error => e
        return error_with_internal_code(e.message,
                                        'simple token api error: Time Out Error', GlobalConstant::ErrorCode.ok,
                                        {}, {}, 'Time Out Error')

      rescue Exception => e

        ApplicationMailer.notify(
            body: {exception: {message: e.message, backtrace: e.backtrace}},
            data: {environment: @environment},
            subject: "Something Went Wrong in : #{self.class}"
        ).deliver
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

      response_data = Oj.load(http_response, mode: :strict) rescue {}

      if response_data['success']
        # Success
        success_result(response_data['data'])
      else
        # API Error
        Rails.logger.info("=*=Simple-Token-API-ERROR=*= #{response_data.inspect}")
        error_with_internal_code(response_data['err']['code'],
                                 'simple token api error',
                                 GlobalConstant::ErrorCode.ok,
                                 {}, response_data['err']['error_data'],
                                 response_data['err']['display_text'])
      end
    end

  end

end

module KycService

  class TestSimpleTokenKycService

    require "uri"
    require "open-uri"
    require "openssl"

    # Initialize
    # @params [String] api_key(mandatory)
    # @params [String] api_secret(mandatory)
    #
    # Sets @api_key, @api_secret, @api_base_url, @version
    #
    def initialize(client_id)
      client = Client.where(id: client_id).first

      @api_key = client.api_key

      r = Aws::Kms.new('saas', 'saas').decrypt(client.api_salt)
      return r unless r.success?

      api_salt_d = r.data[:plaintext]

      r = LocalCipher.new(api_salt_d).decrypt(client.api_secret)
      return r unless r.success?

      @api_secret = r.data[:plaintext]

      @api_base_url = "http://sale.developmentsimpletoken.org:8080"
      @version = 'v1'
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
          "passport_number" => kyc_data[:passport_number] || 'M123456',
          "nationality" => kyc_data[:nationality] || 'INDIAN',
          "passport_file_path" => kyc_data[:passport_file_path] || '/q/qw',
          "selfie_file_path" => kyc_data[:selfie_file_path] || 'w/er/',
          "remoteip" => kyc_data[:remoteip]  || '172.1.1.1'
      }
      endpoint = "/api/#{@version}/kyc/add-kyc/"
      make_post_request(endpoint, custom_params)
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
    def base_params(endpoint, custom_params={})
      request_time = DateTime.now.to_s
      query_param = custom_params.merge("request_time" => request_time).to_query.gsub(/^&/, '')
      str = "#{endpoint}?#{query_param}"
      {
          "request_time" => request_time,
          "signature" => generate_signature(str),
          "api_key" => @api_key
      }
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
      base_params = base_params(endpoint, custom_params)
      raw_url = get_api_url(endpoint) + "?#{base_params.merge(custom_params).to_query}"

      begin
        Timeout.timeout(GlobalConstant::PepoCampaigns.api_timeout) do
          result = URI.parse(raw_url).read
          return JSON.parse(result)
        end
      rescue Timeout::Error => e
        return {"error" => "Timeout Error", "message" => "Error: #{e.message}"}
      rescue => e
        return {"error" => "Exception: Something Went Wrong", "message" => "Exception: #{e.message}"}
      end
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
      base_params = base_params(endpoint, custom_params)
      uri = post_api_uri(endpoint)
      begin
        Timeout.timeout(GlobalConstant::PepoCampaigns.api_timeout) do
          http = setup_request(uri)
          result = http.post(uri.path, base_params.merge(custom_params).to_query)
          return JSON.parse(result.body)
        end
      rescue Timeout::Error => e
        return {"error" => "Timeout Error", "message" => "Error: #{e.message}"}
      rescue => e
        return {"error" => "Something Went Wrong", "message" => "Exception: #{e.message}"}
      end

    end

  end

end

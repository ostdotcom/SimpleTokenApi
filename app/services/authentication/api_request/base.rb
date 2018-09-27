module Authentication::ApiRequest

  class Base < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 10/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @param [String] api_key (mandatory) -  api key of client
    # @param [String] signature (mandatory) - generated signature
    # @param [String] request_time (mandatory) - request time in rfc3339 format -> '2016-02-18T16:40:50+05:30'
    # @param [String] url_path (mandatory) - path of request url
    # @param [Hash] request_parameters (mandatory) - request parameters
    # @param [Boolean] allow_web_based_client (mandatory) - validate web based clients
    #
    # @return [Authentication::ApiRequest::Base]
    #
    def initialize(params)
      super

      @api_key = @params[:api_key]
      @signature = @params[:signature]
      @request_time = request_time
      @url_path = @params[:url_path]
      @request_parameters = @params[:request_parameters]
      @allow_web_based_client = @params[:allow_web_based_client]

      @parsed_request_time = nil
      @api_secret_d = nil

    end

    # Get request time
    #
    # * Author: Aniket
    # * Date: 18/09/2018
    # * Reviewed By:
    #
    def request_time
     fail 'request time function did not override'
    end

    # Get expiry window
    #
    # * Author: Aniket
    # * Date: 18/09/2018
    # * Reviewed By:
    #
    def expiry_window
      fail 'expiry_window function did not override'
    end

    # Get url path
    #
    # * Author: Aniket
    # * Date: 21/09/2018
    # * Reviewed By:
    #
    def get_url_path
      fail 'get_url_path function did not override'
    end

    # Perform
    #
    # * Author: Aman
    # * Date: 27/12/2017
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?

      fetch_client

      r = validate_client
      return r unless r.success?

      success_with_data(client_id: @client.id)

    end

    private

    # Validate and sanitize
    #
    # * Author: Aman
    # * Date: 27/12/2017
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    # Sets @parsed_request_time, @url_path, @request_parameters
    #
    def validate_and_sanitize
      r = validate
      return r unless r.success?

      @url_path = get_url_path
      @parsed_request_time = Time.at(@request_time.to_i)

      return invalid_credentials_response("um_vac_1") unless
          @parsed_request_time && (@parsed_request_time.between?(Time.now - expiry_window, Time.now + expiry_window))

      @request_parameters.permit!

      ["signature"].each do |k|
        @request_parameters.delete(k)
      end

      success
    end

    # Fetch client
    #
    # * Author: Aman
    # * Date: 27/12/2017
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    # Sets @client
    #
    def fetch_client
      @client = Client.get_client_for_api_key_from_memcache(@api_key)
      puts "fetch_client : #{@client.inspect}"
    end

    # Validate client and its signature
    #
    # * Author: Aman
    # * Date: 27/12/2017
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_client

      return invalid_credentials_response('a_ar_b_vc_1') unless @client.present?

      return error_with_identifier('invalid_client_id',
                                   'a_ar_b_vc_2'
      ) if @client.status != GlobalConstant::Client.active_status

      return error_with_identifier('forbidden_api_request',
                                   'a_ar_b_vc_3'
      ) if (!@allow_web_based_client && @client.is_web_host_setup_done?) || @client.is_st_token_sale_client?

      r = decrypt_api_secret

      return error_with_identifier('internal_server_error', 'a_ar_b_vc_4') unless r.success?

      # Note: internal code for this error is same for client not present
      return invalid_credentials_response('a_ar_b_vc_1') unless generate_signature == @signature

      success
    end

    # Generate Signature
    #
    # * Author: Aman
    # * Date: 27/12/2017
    # * Reviewed By:
    #
    # @return [String] expected signature for the api call
    #
    def generate_signature
      digest = OpenSSL::Digest.new('sha256')
      string_to_sign = "#{@url_path}?#{sorted_parameters_query}"
      puts " 1: #{string_to_sign}"
      OpenSSL::HMAC.hexdigest(digest, @api_secret_d, string_to_sign)
    end

    # Decrypt api secret
    #
    # * Author: Aman
    # * Date: 02/01/2018
    # * Reviewed By:
    #
    # Sets @api_secret_d
    #
    # @return [Result::Base]
    #
    def decrypt_api_secret

      if @client.decrypted_api_salt.present?
        api_salt_d = @client.decrypted_api_salt
      else
        r = Aws::Kms.new('saas', 'saas').decrypt(@client.api_salt)
        return r unless r.success?

        @client.memcache_flush
        api_salt_d = r.data[:plaintext]
      end

      r = LocalCipher.new(api_salt_d).decrypt(@client.api_secret)
      return r unless r.success?

      @api_secret_d = r.data[:plaintext]

      success
    end

    # Sort request parameters
    #
    # * Author: Aman
    # * Date: 27/12/2017
    # * Reviewed By:
    #
    # @return [String] request parameters sorted in query format (eg. "q=1&w=2")
    #
    def sorted_parameters_query
      @request_parameters.to_query.gsub(/^&/, '')
    end

    # Invalid credentials response
    #
    # * Author: Aman
    # * Date: 27/12/2017
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def invalid_credentials_response(internal_code)
      error_with_identifier('invalid_or_expired_token', internal_code)
    end

  end

end
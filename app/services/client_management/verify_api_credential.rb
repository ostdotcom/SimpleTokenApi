module ClientManagement

  class VerifyApiCredential < ServicesBase

    EXPIRATION_WINDOW = 5.minutes

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
    #
    # @return [ClientManagement::VerifyApiCredential]
    #
    def initialize(params)
      super

      @api_key = @params[:api_key]
      @signature = @params[:signature]
      @request_time = @params[:request_time]
      @url_path = @params[:url_path]
      @request_parameters = @params[:request_parameters]

      @parsed_request_time = nil
      @api_secret_d = nil

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

      @url_path = "#{@url_path}/"
      @parsed_request_time = Time.at(@request_time.to_i)

      return error_with_data(
          'um_vac_1',
          'Signature has expired',
          'Signature has expired',
          GlobalConstant::ErrorAction.default,
          {}
      ) unless @parsed_request_time && (@parsed_request_time.between?(Time.now - EXPIRATION_WINDOW, Time.now + EXPIRATION_WINDOW))

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

      return invalid_credentials_response('um_vac_2') unless @client.present? &&
          @client.status == GlobalConstant::Client.active_status && !@client.is_web_host_setup_done?

      return invalid_credentials_response('um_vac_3') if @client.is_st_token_sale_client?

      r = decrypt_api_secret

      return error_with_data(
          'um_vac_4',
          'Something Went Wrong',
          'Something Went Wrong. Please try again',
          GlobalConstant::ErrorAction.default,
          {}
      ) unless r.success?

      return invalid_credentials_response('um_vac_5') unless generate_signature == @signature

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
    def invalid_credentials_response(err, display_text = 'Invalid credentials')
      error_with_data(
          err,
          display_text,
          display_text,
          GlobalConstant::ErrorAction.default,
          {}
      )
    end

  end

end
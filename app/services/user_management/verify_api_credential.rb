module UserManagement

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
    # @return [UserManagement::VerifyApiCredential]
    #
    def initialize(params)
      super

      @api_key = @params[:api_key]
      @signature = @params[:signature]
      @request_time = @params[:request_time]
      @url_path = @params[:url_path]
      @request_parameters = @params[:request_parameters]

      @parsed_request_time = nil

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
      @parsed_request_time = DateTime.rfc3339(request_time) rescue nil

      return error_with_data(
          'um_vac_1',
          'Signature has expired',
          'Signature has expired',
          GlobalConstant::ErrorAction.default,
          {}
      ) unless @parsed_request_time && (@parsed_request_time.between?(Time.now - EXPIRATION_WINDOW, Time.now + EXPIRATION_WINDOW))

      ["signature", "api_key"].each do |k|
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
      @client = Client.where(api_key: @api_key).first
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
          @client.status == GlobalConstant::Client.active_status

      generated_signature = generate_signature

      return invalid_credentials_response('um_vac_3') unless generated_signature == @signature

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
      OpenSSL::HMAC.hexdigest(digest, @client.api_secret, string_to_sign)
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
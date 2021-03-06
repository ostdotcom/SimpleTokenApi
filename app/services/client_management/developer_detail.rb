module ClientManagement

  class DeveloperDetail < ServicesBase

    # Initialize
    #
    # * Author: Aniket
    # * Date: 02/07/2018
    # * Reviewed By:
    #
    # @param [Integer] client_id (mandatory) -  client id
    # @param [Integer] admin_id (mandatory) -  admin id
    #
    # @return [ClientManagement::DeveloperDetail]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @admin_id = @params[:admin_id]

      @client = nil
      @api_secret_d = nil
    end

    # Perform
    #
    # * Author: Aniket
    # * Date: 02/07/2018
    # * Reviewed By: Aman
    #
    # @return [Result::Base]
    #
    def perform
      r = validate_and_sanitize
      return r unless r.success?

      fetch_api_keys
      fetch_client_kyc_config_detail
      fetch_active_client_kyc_detail_api_activations

      success_with_data(success_response_data)
    end

    private

    # Validate And Sanitize
    #
    # * Author: Aniket
    # * Date: 02/07/2018
    # * Reviewed By: Aman
    #
    #
    def validate_and_sanitize
      r = validate
      return r unless r.success?

      r = validate_client_and_admin
      return r unless r.success?

      success
    end

    # Client and Admin validate
    #
    # * Author: Aniket/Tejas
    # * Date: 03/07/2018
    # * Reviewed By:
    #
    #
    def validate_client_and_admin

      r = fetch_and_validate_client
      return r unless r.success?

      r = fetch_and_validate_admin
      return r unless r.success?

      success
    end

    # Fetch Secret Decrypt
    #
    # * Author: Aniket
    # * Date: 02/07/2018
    # * Reviewed By: Aman
    #
    # Sets @api_secret_d
    #
    def fetch_api_keys
      api_salt_d = Aws::Kms.new('saas', 'saas').decrypt(@client.api_salt).data[:plaintext]

      @api_secret_d = LocalCipher.new(api_salt_d).decrypt(@client.api_secret).data[:plaintext]
    end

    # Fetch Client Kyc Config Detail
    #
    # * Author: Aniket
    # * Date: 02/07/2018
    # * Reviewed By: Aman
    #
    # Sets @client_kyc_config_detail
    #
    def fetch_client_kyc_config_detail
      @client_kyc_config_detail = @client.client_kyc_config_detail
    end

    # Fetch Client Kyc Detail Api Activations
    #
    # * Author: Aniket
    # * Date: 02/07/2018
    # * Reviewed By: Aman
    #
    # Sets @client_kyc_detail_api_activations
    #
    def fetch_active_client_kyc_detail_api_activations
      @client_kyc_detail_api_activations = ClientKycDetailApiActivation.get_last_active_from_memcache(@client_id)
    end

    # Api response data
    #
    # * Author: Aniket
    # * Date: 02/07/2018
    # * Reviewed By: Aman
    #
    # returns [Hash] api response data
    #
    def success_response_data
      selected_api_fields = @client_kyc_detail_api_activations.present? ?
                                @client_kyc_detail_api_activations.kyc_fields_array + @client_kyc_detail_api_activations.extra_kyc_fields : []


      api_fields_config = GlobalConstant::ClientKycConfigDetail.kyc_fields_config_with_labels + extra_fields_array


      applicable_api_fields = @client_kyc_config_detail.kyc_fields_array + @client_kyc_config_detail.extra_kyc_fields.stringify_keys.keys

      {
          api_key: @client.api_key,
          api_secret: @api_secret_d,
          selected_api_fields: selected_api_fields,
          applicable_api_fields: applicable_api_fields,
          api_fields_config: api_fields_config

      }
    end

    def extra_fields_array
      extra_fields = []
      @client_kyc_config_detail.extra_kyc_fields.each do | key, value |
        extra_fields << {
            value: key,
            display_text: value[:label]
        }
      end
    extra_fields
    end

  end
end

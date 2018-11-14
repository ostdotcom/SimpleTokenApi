module ClientManagement
  class UpdateApiFields < ServicesBase

    # Initialize
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    # @param [Integer] client_id (mandatory) -  client id
    # @param [Integer] admin_id (mandatory) -  admin id
    # @param [Array] set_allowed_keys (mandatory) -  set allowed keys
    #
    # @return [ClientManagement::UpdateApiFields]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @admin_id = @params[:admin_id]
      @set_allowed_keys = @params[:set_allowed_keys]

      @kyc_fields = []
      @extra_kyc_fields = []
    end

    # Perform
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?

      update_api_fields

      success
    end


    # private

    # Validate And Sanitize
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    #
    def validate_and_sanitize
      r = validate
      return r unless r.success?

      r = validate_client_and_admin
      return r unless r.success?

      r = validate_allowed_keys
      return r unless r.success?

      success
    end

    # Client and Admin validate
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    # sets @admin, @client
    #
    def validate_client_and_admin
      r = fetch_and_validate_client
      return r unless r.success?

      r = fetch_and_validate_admin
      return r unless r.success?

      success
    end

    # Validate Allowed Keys
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    # sets client_kyc_config_details
    #
    def validate_allowed_keys
      client_kyc_config_details = ClientKycConfigDetail.get_from_memcache(@client_id)

      @kyc_fields = @set_allowed_keys & client_kyc_config_details.kyc_fields_array

      @extra_kyc_fields = @set_allowed_keys & client_kyc_config_details.extra_kyc_fields.stringify_keys.keys

      unallowed_keys = @set_allowed_keys - (@kyc_fields + @extra_kyc_fields)
      return error_with_identifier('invalid_api_params', 'cm_uaf_vak_1', ['invalid_set_allowed_keys'], 'Invalid field selected') if unallowed_keys.present?

      success
    end

    # Update Api Fields
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    # sets @client_kyc_detail_api_activations
    #
    def update_api_fields
      @client_kyc_detail_api_activations = ClientKycDetailApiActivation.get_last_active_from_memcache(@client_id)

      if @client_kyc_detail_api_activations.blank?
        @client_kyc_detail_api_activations = ClientKycDetailApiActivation.new(client_id: @client_id,
                                                                              kyc_fields: 0,
                                                                              extra_kyc_fields: [],
                                                                              status: GlobalConstant::ClientKycDetailApiActivation.active_status,
                                                                              last_acted_by: @admin_id)
      end

      @client_kyc_detail_api_activations.extra_kyc_fields = @extra_kyc_fields
      @client_kyc_detail_api_activations.kyc_fields = 0
      @kyc_fields.each do |allowed_key|

        @client_kyc_detail_api_activations.send("set_" + allowed_key)
      end

      @client_kyc_detail_api_activations.source = GlobalConstant::AdminActivityChangeLogger.web_source

      @client_kyc_detail_api_activations.save! if @client_kyc_detail_api_activations.changed?
    end

  end
end
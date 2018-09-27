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
      unallowed_keys = @set_allowed_keys - client_kyc_config_details.kyc_fields_array

      return error_with_identifier('invalid_api_params', 'cm_uaf_vak_1', 'invalid_allowed_keys') if unallowed_keys.present?

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


      if @set_allowed_keys == []
        return if @client_kyc_detail_api_activations.blank?
        mark_previous_kyc_detail_api_activation_row_as_inactive
      else
        if @client_kyc_detail_api_activations.present?
          return if (@set_allowed_keys - @client_kyc_detail_api_activations.allowed_keys_array).blank? &&
              (@client_kyc_detail_api_activations.allowed_keys_array - @set_allowed_keys).blank?
          mark_previous_kyc_detail_api_activation_row_as_inactive
        end

        ckda_obj = ClientKycDetailApiActivation.new(client_id: @client_id,
                                                    allowed_keys: 0,
                                                    status: GlobalConstant::ClientKycDetailApiActivation.active_status,
                                                    created_by: @admin_id,
                                                    updated_by: @admin_id)

        @set_allowed_keys.each do |allowed_key|
          ckda_obj.send("set_" + allowed_key)
        end
        ckda_obj.save!
      end

    end

    # Mark the previous kyc detail api activation row as inactive
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    #
    def mark_previous_kyc_detail_api_activation_row_as_inactive
      @client_kyc_detail_api_activations.status = GlobalConstant::ClientKycDetailApiActivation.inactive_status
      @client_kyc_detail_api_activations.updated_by = @admin_id
      @client_kyc_detail_api_activations.save!
    end

  end
end
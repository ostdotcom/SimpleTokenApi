module ClientManagement
  class GetAutoApproveSetting < ServicesBase

    # Initialize
    #
    # * Author: Aniket
    # * Date: 03/07/2018
    # * Reviewed By:
    #
    # @param [Integer] admin_id (mandatory) -  admin id
    # @param [Integer] client_id (mandatory) -  client id
    #
    # @return [ClientManagement::GetAutoApproveSetting]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @admin_id = @params[:admin_id]

      @client_kyc_pass_setting = nil
    end

    # Perform
    #
    # * Author: Aniket
    # * Date: 03/07/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform
      r = validate_and_sanitize
      return r unless r.success?

      fetch_client_auto_approve_setting

      success_with_data(success_response_data)
    end

    private

    # Validate And Sanitize
    #
    # * Author: Aniket/Tejas
    # * Date: 03/07/2018
    # * Reviewed By:
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
    # Sets @admin, @client
    #
    def validate_client_and_admin

      r = fetch_and_validate_client
      return r unless r.success?

      r = fetch_and_validate_admin
      return r unless r.success?

      success
    end

    # Fetch Client Auto Approve Setting
    #
    # * Author: Aniket/Tejas
    # * Date: 03/07/2018
    # * Reviewed By:
    #
    # Sets @client_kyc_pass_setting
    #
    def fetch_client_auto_approve_setting
      @client_kyc_pass_setting = ClientKycPassSetting.get_active_setting_from_memcache(@client_id)
    end


    # Api response data
    #
    # * Author: Aniket/Tejas
    # * Date: 03/07/2018
    # * Reviewed By:
    #
    # returns [Hash] api response data
    #
    def success_response_data
      {
          client_kyc_pass_setting: {
              approve_type: @client_kyc_pass_setting.approve_type,
              fr_match_percent: @client_kyc_pass_setting.face_match_percent.to_i,
              orc_fields: @client_kyc_pass_setting.ocr_comparison_fields_array
          }
      }
    end

  end
end

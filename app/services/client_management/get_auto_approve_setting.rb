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
    # @return [ClientManagement::GetAutoApproveSetting.new()]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @admin_id = @params[:admin_id]

      @client_auto_approve_setting = nil
      @ocr_comparison_columns = nil
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
    # Sets @client_auto_approve_setting, @ocr_comparison_columns
    #
    def fetch_client_auto_approve_setting
      @client_auto_approve_setting = ClientKycAutoApproveSetting.get_from_memcache(@client_id)

      if @client_auto_approve_setting.present?
        @ocr_comparison_columns = ClientKycAutoApproveSetting.get_bits_set_for_ocr_comparison_columns(@client_auto_approve_setting.ocr_comparison_columns)
      end

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

      current_status = @client_auto_approve_setting.present? ? GlobalConstant::ClientKycAutoApproveSettings.web_status_auto : GlobalConstant::ClientKycAutoApproveSettings.web_status_manual

      response = {
         current_status:current_status,
         recommended_setting:{
             fr_match_percent: GlobalConstant::ClientKycAutoApproveSettings.recommended_fr_percent,
             active_ocr:ClientKycAutoApproveSetting.ocr_comparison_columns_config.keys
         }
      }

      return response unless @client_auto_approve_setting.present?

      response[:client_selected_setting] = {
          fr_match_percent: @client_auto_approve_setting.face_match_percent.to_i,
          active_ocr: @ocr_comparison_columns
      }

      response
    end

  end
end

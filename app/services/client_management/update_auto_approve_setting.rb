module ClientManagement
  class UpdateAutoApproveSetting < ServicesBase

    # Initialize
    #
    # * Author: Aniket
    # * Date: 04/07/2018
    # * Reviewed By:
    #
    # @param [Integer] admin_id (mandatory) -  admin id
    # @param [Integer] client_id (mandatory) -  client id
    # @param [String] auto_approve_status (mandatory) - auto approve status (auto/manual)
    # @param [Array] ocr_auto_approve_fields (optional) - ocr auto approve fields
    # @param [Integer] fr_match_percent (optional) - Facial Recogition match percent
    #
    # @return [ClientManagement::UpdateAutoApproveSetting.new()]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @admin_id = @params[:admin_id]

      @auto_approve_status = @params[:auto_approve_status]
      @ocr_auto_approve_fields = @params[:ocr_auto_approve_fields]
      @fr_match_percent = @params[:fr_match_percent]

    end

    # Perform
    #
    # * Author: Aniket
    # * Date: 02/07/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?

      inactive_auto_approve_setting
      update_auto_approve_setting

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

      r = validate_ocr_fields
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


    def validate_ocr_fields

      remaining_fields = @ocr_auto_approve_fields - ClientKycAutoApproveSetting.ocr_comparison_columns_config.keys
      message = "wrong fields :- #{remaining_fields}"

      return error_with_data(
          's_cm_uaas_1',
          message,
          'parameters passed are not correct',
          GlobalConstant::ErrorAction.default,
          {}
      ) if remaining_fields.count > 0


      success
    end

    # Update Inactive Auto Approve Setting
    #
    # * Author: Aniket
    # * Date: 04/07/2018
    # * Reviewed By:
    #
    #
    def inactive_auto_approve_setting
      auto_approve_setting = ClientKycAutoApproveSetting.get_from_memcache(@client_id)
      if auto_approve_setting.present?
        auto_approve_setting.status = GlobalConstant::ClientKycAutoApproveSettings.inactive_status
        auto_approve_setting.save!
      end
    end

    # Set Auto Approve Setting
    #
    # * Author: Aniket
    # * Date: 04/07/2018
    # * Reviewed By
    #
    def update_auto_approve_setting

      return if @auto_approve_status == GlobalConstant::ClientKycAutoApproveSettings.web_status_manual

      db_entity = {
          client_id: @client_id,
          face_match_percent: @fr_match_percent,
          ocr_comparison_columns: ocr_comparison_bit_value,
          status: GlobalConstant::ClientKycAutoApproveSettings.active_status
      }

      ClientKycAutoApproveSetting.create!(db_entity)

      success
    end

    # Get OCR Comparison Bitwise Value
    #
    # * Author: Aniket
    # * Date: 04/07/2018
    # * Reviewed By
    #
    def ocr_comparison_bit_value

      ocr_comparison_value = 0
      @ocr_auto_approve_fields.each do |ocr_field|
        ocr_comparison_value += ClientKycAutoApproveSetting.ocr_comparison_columns_config[ocr_field]
      end

      ocr_comparison_value
    end



    # Client auto approve success details
    #
    # * Author: Aniket
    # * Date: 04/07/2018
    # * Reviewed By:
    #
    # @return [Hash] hash of client's kyc auto approve
    #
    def success_response_data
      {
      }
    end

  end
end



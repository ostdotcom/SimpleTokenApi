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
    # @param [String] approve_status (mandatory) - approve status (auto/manual)
    # @param [Array] ocr_auto_approve_fields (optional) - ocr auto approve fields
    # @param [Integer] fr_match_percent (optional) - Facial Recogition match percent
    #
    # @return [ClientManagement::UpdateAutoApproveSetting]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @admin_id = @params[:admin_id]

      @auto_approve_status = @params[:approve_status]
      @ocr_auto_approve_fields = @params[:auto_approve_fields]
      @fr_match_percent = @params[:fr_match_percent].to_i

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

      r = fetch_and_validate_auto_approve_setting
      return r unless r.success?

      inactive_auto_approve_setting

      update_auto_approve_setting

      trigger_reprocess_kyc_auto_approve_rescue_task if can_trigger_rescue_task

      success
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
    # sets @admin, @client
    #
    def validate_client_and_admin
      r = fetch_and_validate_client
      return r unless r.success?

      r = fetch_and_validate_admin
      return r unless r.success?

      success
    end

    def validate_ocr_fields
      return error_with_data(
          's_cm_uaas_vof_1',
          'Invalid parameters',
          'Invalid auto approve status',
          GlobalConstant::ErrorAction.default,
          {}
      ) if [GlobalConstant::ClientKycAutoApproveSetting.manual_approve_web_status,
            GlobalConstant::ClientKycAutoApproveSetting.auto_approve_web_status].exclude?(@auto_approve_status)

      if @auto_approve_status == GlobalConstant::ClientKycAutoApproveSetting.manual_approve_web_status
        @ocr_auto_approve_fields = []
        @fr_match_percent = nil
        return success
      end

      return error_with_data(
          's_cm_uaas_vof_2',
          'Invalid parameters',
          'Invalid auto approve fields data',
          GlobalConstant::ErrorAction.default,
          {}
      ) if !@ocr_auto_approve_fields.is_a?(Array)

      return error_with_data(
          's_cm_uaas_vof_3',
          'Invalid values for ocr_auto_approve_fields',
          '',
          GlobalConstant::ErrorAction.default,
          {},
          {ocr_auto_approve_fields: "Select atlease one field"}
      ) if @ocr_auto_approve_fields.count < 1

      remaining_fields = @ocr_auto_approve_fields - ClientKycAutoApproveSetting.ocr_comparison_fields_config.keys

      return error_with_data(
          's_cm_uaas_vof_4',
          'Invalid values for ocr_auto_approve_fields',
          '',
          GlobalConstant::ErrorAction.default,
          {},
          {ocr_auto_approve_fields: "Invalid fields-#{remaining_fields.join(',')} selected"}
      ) if remaining_fields.count > 0

      return error_with_data(
          's_cm_uaas_vof_5',
          'Invalid Fr percent',
          '',
          GlobalConstant::ErrorAction.default,
          {},
          {fr_match_percent: "FR percent should be greater than 0"}
      ) if @fr_match_percent == 0

      success
    end

    # Fetch and validate auto approve setting
    #
    # * Author: Aniket/Tejas
    # * Date: 09/07/2018
    # * Reviewed By:
    #
    # @return [Resut::Base]
    #
    # Sets @saved_auto_approve_setting
    #
    def fetch_and_validate_auto_approve_setting
      @saved_auto_approve_setting = ClientKycAutoApproveSetting.get_active_setting_from_memcache(@client_id)

      if @saved_auto_approve_setting.blank?
        return error_with_data(
            's_cm_uaas_fvaas_1',
            'Invalid parameters',
            'Invalid auto approve status',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @auto_approve_status == GlobalConstant::ClientKycAutoApproveSetting.manual_approve_web_status

      else
        modified_fields = @ocr_auto_approve_fields - @saved_auto_approve_setting.ocr_comparison_fields_array
        modified_fields += @saved_auto_approve_setting.ocr_comparison_fields_array - @ocr_auto_approve_fields

        return error_with_data(
            's_cm_uaas_fvaas_2',
            'Invalid parameters',
            'Modified ocr auto approve fields are already active',
            GlobalConstant::ErrorAction.default,
            {}
        ) if modified_fields.count == 0

      end

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

      if @saved_auto_approve_setting.present?
        @saved_auto_approve_setting.status = GlobalConstant::ClientKycAutoApproveSetting.inactive_status
        @saved_auto_approve_setting.save!
      end
    end

    # Set Auto Approve Setting
    #
    # * Author: Aniket
    # * Date: 04/07/2018
    # * Reviewed By
    #
    def update_auto_approve_setting
      return if @auto_approve_status == GlobalConstant::ClientKycAutoApproveSetting.manual_approve_web_status

      db_entity = {
          client_id: @client_id,
          face_match_percent: @fr_match_percent,
          ocr_comparison_fields: ocr_comparison_bit_value,
          status: GlobalConstant::ClientKycAutoApproveSetting.active_status
      }

      ClientKycAutoApproveSetting.create!(db_entity)
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
        ocr_comparison_value += ClientKycAutoApproveSetting.ocr_comparison_fields_config[ocr_field]
      end

      ocr_comparison_value
    end

    # Check whether rescue task can trigger or not
    #
    # * Author: Aniket
    # * Date: 06/07/2018
    # * Reviewed By
    #
    def can_trigger_rescue_task

      return false if @auto_approve_status == GlobalConstant::ClientKycAutoApproveSetting.manual_approve_web_status

      return true if @saved_auto_approve_setting.blank?

      removed_ocr_fields = @saved_auto_approve_setting.ocr_comparison_fields_array - @ocr_auto_approve_fields

      if (@fr_match_percent < @saved_auto_approve_setting.face_match_percent.to_i) || (removed_ocr_fields.count > 0)
        return true
      end

      false
    end

    # Trigger rescue task for auto approve user
    #
    # * Author: Aniket
    # * Date: 06/07/2018
    # * Reviewed By
    #
    def trigger_reprocess_kyc_auto_approve_rescue_task

      BgJob.enqueue(
          ReprocessKycAutoApproveJob,
          {
              client_id: @client_id
          }
      )
      Rails.logger.info('---- enqueue_job ReprocessKycAutoApproveJob done')

    end

  end
end



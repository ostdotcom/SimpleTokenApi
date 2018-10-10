module ClientManagement
  class UpdateAutoApproveSetting < ServicesBase

    TIMEFRAME_FOR_SETTING_UPDATE_IN_MINUTES = 1
    MIN_OCR_COMPARISON_FIELDS_SELECTION_COUNT = 1
    MIN_FR_MATCH_PERCENT = 20

    # Initialize
    #
    # * Author: Aniket
    # * Date: 04/07/2018
    # * Reviewed By:
    #
    # @param [Integer] admin_id (mandatory) -  admin id
    # @param [Integer] client_id (mandatory) -  client id
    # @param [String] approve_type (mandatory) - approve status (auto/manual)
    # @param [Array] ocr_comparison_fields (mandatory) - ocr auto approve fields
    # @param [Integer] fr_match_percent (mandatory) - Facial Recogition match percent
    #
    # @return [ClientManagement::UpdateAutoApproveSetting]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @admin_id = @params[:admin_id]
      @addendum_client_ids = GlobalConstant::Base.kyc_app['addendum_client_ids']

      @approve_type = @params[:approve_type]
      @ocr_comparison_fields = @params[:ocr_comparison_fields]
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

      inactive_kyc_pass_setting

      create_kyc_pass_setting

      trigger_reprocess_kyc_auto_approve_rescue_task

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
      r = addendum_client_id_present?
      return r unless r.success?

      r = validate
      return r unless r.success?

      r = validate_client_and_admin
      return r unless r.success?

      r = validate_ocr_comparison_fields
      return r unless r.success?

      success
    end


    def addendum_client_id_present?
      return error_with_data(
          's_cm_uaas_acip_1',
          'Invalid client id',
          "Kindly, Sign the addendum to use the Artificial Intelligence feature.",
          GlobalConstant::ErrorAction.default,
          {}
      ) if @addendum_client_ids.include?(@client_id.to_i)
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

    def validate_ocr_comparison_fields
      return error_with_data(
          's_cm_uaas_vof_1',
          'Invalid parameters',
          'Invalid approve type',
          GlobalConstant::ErrorAction.default,
          {}
      ) if [GlobalConstant::ClientKycPassSetting.manual_approve_type,
            GlobalConstant::ClientKycPassSetting.auto_approve_type].exclude?(@approve_type)
      
      return error_with_data(
          's_cm_uaas_vof_2',
          'Invalid parameters',
          'Invalid Optical Character Recognition fields data',
          GlobalConstant::ErrorAction.default,
          {}
      ) if !@ocr_comparison_fields.is_a?(Array)

      return error_with_data(
          's_cm_uaas_vof_3',
          'Invalid values for ocr_comparison_fields',
          'Select at least one Optical Character Recognition field',
          GlobalConstant::ErrorAction.default,
          {},
          {ocr_comparison_fields: "Select at least one Optical Character Recognition field"}
      ) if @ocr_comparison_fields.count < MIN_OCR_COMPARISON_FIELDS_SELECTION_COUNT

      remaining_fields = @ocr_comparison_fields - ClientKycPassSetting.ocr_comparison_fields_config.keys
      return error_with_data(
          's_cm_uaas_vof_4',
          'Invalid values for ocr_comparison_fields',
          '',
          GlobalConstant::ErrorAction.default,
          {},
          {ocr_comparison_fields: "Invalid Optical Character Recognition fields-#{remaining_fields.join(',')} selected"}
      ) if remaining_fields.count > 0

      return error_with_data(
          's_cm_uaas_vof_5',
          'Invalid Facial Recognition percent',
          "Facial Recognition percent cannot be less than #{MIN_FR_MATCH_PERCENT}",
          GlobalConstant::ErrorAction.default,
          {},
          {fr_match_percent: "Facial Recognition percent cannot be less than #{MIN_FR_MATCH_PERCENT}"}
      ) if @fr_match_percent < MIN_FR_MATCH_PERCENT

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
      @saved_auto_approve_setting = ClientKycPassSetting.get_active_setting_from_memcache(@client_id)

      modified_fields = @ocr_comparison_fields - @saved_auto_approve_setting.ocr_comparison_fields_array
      modified_fields += @saved_auto_approve_setting.ocr_comparison_fields_array - @ocr_comparison_fields

      if modified_fields.count == 0 &&
         @fr_match_percent == @saved_auto_approve_setting.face_match_percent.to_i &&
         @approve_type == @saved_auto_approve_setting.approve_type
        return error_with_data(
            's_cm_uaas_fvaas_1',
            'Invalid parameters',
            'You are choosing to save existing settings.',
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

      difference = TIMEFRAME_FOR_SETTING_UPDATE_IN_MINUTES - ((Time.now.to_i - @saved_auto_approve_setting.created_at.to_i)/60) #in minutes
      return error_with_data(
          's_cm_uaas_fvaas_2',
          'Artificla Intelligence Settings cannot be updated',
          "Artificial Intelligence Settings can be updated after #{difference} minutes",
          GlobalConstant::ErrorAction.default,
          {}
      ) if difference > 0

      success
    end

    # Update Inactive Auto Approve Setting
    #
    # * Author: Aniket
    # * Date: 04/07/2018
    # * Reviewed By:
    #
    #
    def inactive_kyc_pass_setting
      @saved_auto_approve_setting.status = GlobalConstant::ClientKycPassSetting.inactive_status
      @saved_auto_approve_setting.save!
    end

    # Make entry of kyc pass setting
    #
    # * Author: Aniket
    # * Date: 04/07/2018
    # * Reviewed By
    #
    def create_kyc_pass_setting
      db_entity = {
          client_id: @client_id,
          face_match_percent: @fr_match_percent,
          ocr_comparison_fields: ocr_comparison_bit_value,
          approve_type: @approve_type,
          status: GlobalConstant::ClientKycPassSetting.active_status
      }
      ClientKycPassSetting.create!(db_entity)
    end

    # Get OCR Comparison Bitwise Value
    #
    # * Author: Aniket
    # * Date: 04/07/2018
    # * Reviewed By
    #
    def ocr_comparison_bit_value
      ocr_comparison_value = 0
      @ocr_comparison_fields.each do |ocr_field|
        ocr_comparison_value += ClientKycPassSetting.ocr_comparison_fields_config[ocr_field]
      end

      ocr_comparison_value
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
              fr_match_percent: @fr_match_percent,
              ocr_comparison_fields: @ocr_comparison_fields,
              approve_type: @approve_type
          }
      }

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



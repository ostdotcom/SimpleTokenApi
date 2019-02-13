module ClientManagement
  class GetMfaSessionSettings < ServicesBase

    # Initialize
    #
    # * Author: Mayur
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    # @param [Hash] params (mandatory)
    #
    # @return [ClientManagement::GetMfaSessionSettings]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @admin_id = @params[:admin_id]

      @admin_session_settings = []

    end

    # Perform
    #
    # * Author: Mayur
    # * Date: 07/02/2019
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?

      success_with_data(get_mfa_session_settings)
    end


    private


    # Validate And Sanitize
    #
    # * Author: Mayur
    # * Date: 07/02/2019
    # * Reviewed By:
    #
    #
    def validate_and_sanitize
      r = validate
      return r unless r.success?

      r = fetch_and_validate_client
      return r unless r.success?


      r = fetch_and_validate_admin
      return r unless r.success?

      success
    end

    # get mfa session settings
    #
    # * Author: Mayur
    # * Date: 07/02/2019
    # * Reviewed By:
    #
    #
    def get_mfa_session_settings
      result_obj = {}
      @admin_session_settings = AdminSessionSetting.get_active_from_memcache(@client_id)
      if @admin_session_settings.length == 1
        result_obj[:admin_setting] = create_session_info_hash(@admin_session_settings.first)
        result_obj[:has_sa_setting] = 0
      else
        if @admin_session_settings.first.admin_types_array.include?(GlobalConstant::Admin.super_admin_role)
          result_obj[:super_admin_setting] = create_session_info_hash(@admin_session_settings.first)
          result_obj[:admin_setting] = create_session_info_hash(@admin_session_settings.last)
        else
          result_obj[:super_admin_setting] = create_session_info_hash(@admin_session_settings.last)
          result_obj[:admin_setting] = create_session_info_hash(@admin_session_settings.first)
        end
        result_obj[:has_sa_setting] = 1
      end
      result_obj
    end

    # create session info hash
    #
    # * Author: Mayur
    # * Date: 07/02/2019
    # * Reviewed By:
    #
    #
    def create_session_info_hash(admin_setting)
      {
          mfa_type: admin_setting.mfa_frequency.zero? ? 0 : 1,
          mfa_frequency: admin_setting.mfa_frequency / 1.day.to_i,
          session_timeout: admin_setting.session_inactivity_timeout / 1.hour.to_i
      }
    end
  end
end
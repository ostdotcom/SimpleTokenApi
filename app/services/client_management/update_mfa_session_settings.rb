module ClientManagement
  class UpdateMfaSessionSettings < ServicesBase

    # Initialize
    #
    # * Author: Tejas
    # * Date: 07/02/2019
    # * Reviewed By:
    #
    # @param [Integer] client_id (mandatory) -  client id
    # @param [Integer] admin_id (mandatory) -  admin id
    # @param [String] admin_setting (mandatory) -  admin setting
    # @param [String] super_admin_setting (mandatory) -  super admin setting
    # @param [Boolean] has_sa_setting (optional) -  has sa setting
    #
    # @return [ClientManagement::UpdateMfaSessionSettings]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @admin_id = @params[:admin_id]
      @admin_setting = @params[:admin_setting] || {}
      @super_admin_setting = @params[:super_admin_setting] || {}
      @has_sa_setting = @params[:has_sa_setting].to_i

      @admin_session_settings = []
    end

    # Perform
    #
    # * Author: Tejas
    # * Date: 07/02/2019
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?

      fetch_admin_session_settings

      r = update_admin_session_settings
      return r unless r.success?

      r = update_admins_session_inactivity_timeout
      return r unless r.success?

      success
    end


    private

    # Validate And Sanitize
    #
    # * Author: Tejas
    # * Date: 07/02/2019
    # * Reviewed By:
    #
    #
    def validate_and_sanitize
      r = validate
      return r unless r.success?

      r = validate_client_and_admin
      return r unless r.success?

      r = validate_mfa_frequency_and_session_inactivity_timeout
      return r unless r.success?

      success
    end

    # Client and Admin validate
    #
    # * Author: Tejas
    # * Date: 07/02/2019
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

    # Validate Mfa Frequency And Session Inactivity Timeout
    #
    # * Author: Tejas
    # * Date: 08/02/2019
    # * Reviewed By:
    #
    def validate_mfa_frequency_and_session_inactivity_timeout
      err_data = {}

      admin_setting_err = {}
      admin_setting_err[:session_timeout] = 'Please select a session timeout within the range mentioned.' if !is_valid_session_inactivity_timeout?(normal_admin_setting)
      admin_setting_err[:mfa_type] = 'Invalid Mfa Type.' if !is_valid_mfa_type?(normal_admin_setting)
      admin_setting_err[:mfa_frequency] = 'Please select a Mfa Frequency within the range mentioned.' if !is_valid_mfa_frequency?(normal_admin_setting)

      err_data[:admin_setting] = admin_setting_err if admin_setting_err.present?

      err_data[:has_sa_setting] = 'Invalid Super Admin Setting.' if GlobalConstant::AdminSessionSetting.allowed_mfa_types.exclude?(@has_sa_setting)

      if @has_sa_setting == 1
        super_admin_setting_err = {}
        super_admin_setting_err[:session_timeout] = 'Please select a session timeout within the range mentioned.' if !is_valid_session_inactivity_timeout?(super_admin_setting)
        super_admin_setting_err[:mfa_type] = 'Invalid Mfa Type.' if !is_valid_mfa_type?(super_admin_setting)
        super_admin_setting_err[:mfa_frequency] = 'Please select a Mfa Frequency within the range mentioned.' if !is_valid_mfa_frequency?(super_admin_setting)
        err_data[:super_admin_setting] = super_admin_setting_err if super_admin_setting_err.present?
      end

      return error_with_identifier('invalid_api_params',
                                   'cm_umss_vmfasit_1',
                                   '',
                                   '',
                                   err_data
      ) if err_data.present?

      success
    end

    # fetch admin session settings
    #
    # * Author: Tejas
    # * Date: 07/02/2019
    # * Reviewed By:
    #
    # sets @admin_session_settings
    #
    #
    def fetch_admin_session_settings
      @admin_session_settings = AdminSessionSetting.get_active_from_memcache(@client_id)
    end

    # Update Client Whitelist Detail
    #
    # * Author: Tejas
    # * Date: 07/02/2019
    # * Reviewed By:
    #
    # sets @active_client_whitelist_detail_obj
    #
    # @return [Result::Base]
    #
    def update_admin_session_settings

      super_admin_setting_obj, admin_setting_obj = nil, nil

      if @admin_session_settings.length == 1
        admin_setting_obj = @admin_session_settings.first
      else
        if @admin_session_settings.first.admin_types_array.include?(GlobalConstant::Admin.normal_admin_role)
          admin_setting_obj = @admin_session_settings.first
          super_admin_setting_obj = @admin_session_settings.last
        else
          admin_setting_obj = @admin_session_settings.last
          super_admin_setting_obj = @admin_session_settings.first
        end
      end

      has_diff_super_admin_settings_in_db = super_admin_setting_obj.present?


      admin_setting_obj.session_inactivity_timeout = get_session_timeout(normal_admin_setting)
      admin_setting_obj.mfa_frequency = get_mfa_frequency(normal_admin_setting)


      if update_different_super_admin_setting?

        if has_diff_super_admin_settings_in_db
          super_admin_setting_obj.session_inactivity_timeout = get_session_timeout(super_admin_setting)
          super_admin_setting_obj.mfa_frequency = get_mfa_frequency(super_admin_setting)
        else
          super_admin_setting_obj = AdminSessionSetting.new(
              client_id: @client_id,
              session_inactivity_timeout: get_session_timeout(super_admin_setting),
              mfa_frequency: get_mfa_frequency(super_admin_setting),
              last_acted_by: @admin_id,
              status: GlobalConstant::AdminSessionSetting.active_status,
              log_sync: true,
              source: GlobalConstant::AdminActivityChangeLogger.web_source
          )
          super_admin_setting_obj.send("set_#{GlobalConstant::Admin.super_admin_role}")

          admin_setting_obj.admin_types = 0
          admin_setting_obj.send("set_#{GlobalConstant::Admin.normal_admin_role}")
        end

      else

        if has_diff_super_admin_settings_in_db
          super_admin_setting_obj.status = GlobalConstant::AdminSessionSetting.deleted_status
          admin_setting_obj.send("set_#{GlobalConstant::Admin.super_admin_role}")
        end

      end

      is_admin_session_setting_obj_changed = false
      if admin_setting_obj.changed?
        admin_setting_obj.source = GlobalConstant::AdminActivityChangeLogger.web_source
        admin_setting_obj.save!
        is_admin_session_setting_obj_changed = true
      end

      if super_admin_setting_obj.present? && super_admin_setting_obj.changed?
        super_admin_setting_obj.source = GlobalConstant::AdminActivityChangeLogger.web_source
        super_admin_setting_obj.save!
        is_admin_session_setting_obj_changed = true
      end

      return error_with_data(
          'cm_umss_uass_1',
          'Invalid parameters',
          'You are choosing to save existing settings.',
          GlobalConstant::ErrorAction.default,
          {}
      ) if !is_admin_session_setting_obj_changed

      success
    end

    # Update Admins Session Inactivity Timeout
    #
    # * Author: Tejas
    # * Date: 11/02/2019
    # * Reviewed By:
    #
    # sets admin
    #
    # @return [Result::Base]
    #
    def update_admins_session_inactivity_timeout
      admins = Admin.get_all_admins_from_memcache(@client_id)

      admins.each do |admin|

        admin.session_inactivity_timeout = (admin.role == GlobalConstant::Admin.normal_admin_role) ?
                                               get_session_timeout(normal_admin_setting) :
                                               get_session_timeout(super_admin_setting)

        admin.save! if admin.changed?
      end

      success
    end

    # Is Valid Mfa Frequency
    #
    # * Author: Tejas
    # * Date: 07/02/2019
    # * Reviewed By:
    #
    # @return [Boolean]
    #
    def is_valid_mfa_frequency?(setting)
      (setting[:mfa_frequency].to_i >= 0) &&
          (setting[:mfa_frequency].to_i <= GlobalConstant::AdminSessionSetting.max_mfa_frequency_value) &&
          (Util::CommonValidateAndSanitize.is_integer?(setting[:mfa_frequency]))
    end

    # Is Valid Mfa Frequency
    #
    # * Author: Tejas
    # * Date: 07/02/2019
    # * Reviewed By:
    #
    # @return [Boolean]
    #
    def is_valid_session_inactivity_timeout?(setting)
      (setting[:session_timeout].to_i >= GlobalConstant::AdminSessionSetting.min_session_inactivity_timeout) &&
          (setting[:session_timeout].to_i <= GlobalConstant::AdminSessionSetting.max_session_inactivity_timeout) &&
          (Util::CommonValidateAndSanitize.is_integer?(setting[:session_timeout]))
    end

    # Is Valid Mfa Type
    #
    # * Author: Tejas
    # * Date: 12/02/2019
    # * Reviewed By:
    #
    # @return [Boolean]
    #
    def is_valid_mfa_type?(setting)
      GlobalConstant::AdminSessionSetting.allowed_mfa_types.include?(setting[:mfa_type].to_i)
    end


    # settings of normal admin
    #
    # * Author: Tejas
    # * Date: 12/02/2019
    # * Reviewed By:
    #
    # @return [Hash] session settings
    #
    def normal_admin_setting
      @admin_setting
    end

    #  settings of super admin
    #
    # * Author: Tejas
    # * Date: 12/02/2019
    # * Reviewed By:
    #
    # @return [Hash] session settings
    #
    def super_admin_setting
      update_different_super_admin_setting? ? @super_admin_setting : @admin_setting
    end


    # is true If different super admin settings
    #
    # * Author: Tejas
    # * Date: 12/02/2019
    # * Reviewed By:
    #
    # @return [Boolean]
    #
    def update_different_super_admin_setting?
      @has_sa_setting == 1
    end


    # Session inactivity timeout in seconds
    #
    # * Author: Tejas
    # * Date: 12/02/2019
    # * Reviewed By:
    #
    # @return [Integer]
    #
    def get_session_timeout(setting)
      setting[:session_timeout].to_i.hours.to_i
    end

    # MFA Frequency in seconds
    #
    # * Author: Tejas
    # * Date: 12/02/2019
    # * Reviewed By:
    #
    # @return [Integer]
    #
    def get_mfa_frequency(setting)
      setting[:mfa_type] == 0 ? 0 : setting[:mfa_frequency].to_i.days.to_i
    end

  end
end
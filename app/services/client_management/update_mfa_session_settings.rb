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

      @admin_session_settings = nil
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

      r = fetch_admin_session_settings
      return r unless r.success?

      r = update_admin_session_settings
      return r unless r.success?

      r = update_admins_session_inactivity_timeout
      return r unless r.success?

      success_with_data({})
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

      err_data[:admin_session_inactivity_timeout] = 'Please select a session timeout within the range mentioned.' if !is_valid_session_inactivity_timeout(@admin_setting)
      err_data[:admin_mfa_frequency] = 'Please select a Mfa Frequency within the range mentioned.' if !is_valid_mfa_frequency(@admin_setting)
      err_data[:super_admin_session_inactivity_timeout] = 'Please select a session timeout within the range mentioned.' if !is_valid_session_inactivity_timeout(@super_admin_setting)

      err_data[:super_admin_mfa_frequency] = 'Please select a Mfa Frequency within the range mentioned.' if !is_valid_mfa_frequency(@super_admin_setting)

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
    # @return [Result::Base]
    #
    def fetch_admin_session_settings
      @admin_session_settings = AdminSessionSetting.get_active_from_memcache(@client_id)
      success
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
      if @admin_setting.present?
        admin_session_timeout = @admin_setting[:session_timeout].to_i.hours.to_i
        admin_mfa_frequency = @admin_setting[:mfa_type] == GlobalConstant::AdminSessionSetting.default_mfa_frequency ?
                                  GlobalConstant::AdminSessionSetting.default_mfa_frequency :
                                  @admin_setting[:mfa_frequency].to_i.days.to_i
        admin_setting_obj = @admin_session_settings.first.admin_types == GlobalConstant::Admin.normal_admin_role ?
                                @admin_session_settings.first : @admin_session_settings.last
      end
      if @super_admin_setting.present?
        super_admin_session_timeout = @super_admin_setting[:session_timeout].to_i.hours.to_i
        super_admin_mfa_frequency = @super_admin_setting[:mfa_type] == GlobalConstant::AdminSessionSetting.default_mfa_frequency ?
                                        GlobalConstant::AdminSessionSetting.default_mfa_frequency :
                                        @super_admin_setting[:mfa_frequency].to_i.days.to_i
        super_admin_setting_obj = @admin_session_settings.first.admin_types == GlobalConstant::Admin.normal_admin_role ?
                                      @admin_session_settings.last : @admin_session_settings.first
      end
      if @admin_session_settings.length == 2 and !@has_sa_setting.zero?
        super_admin_setting_obj.session_inactivity_timeout = super_admin_session_timeout
        super_admin_setting_obj.mfa_frequency = super_admin_mfa_frequency
        super_admin_setting_obj.source = GlobalConstant::AdminActivityChangeLogger.web_source
        super_admin_setting_obj.log_sync = true
        super_admin_setting_obj.save! if super_admin_setting_obj.changed?

        admin_setting_obj.session_inactivity_timeout = admin_session_timeout
        admin_setting_obj.mfa_frequency = admin_mfa_frequency
        admin_setting_obj.source = GlobalConstant::AdminActivityChangeLogger.web_source
        admin_setting_obj.log_sync = true
        admin_setting_obj.save! if admin_setting_obj.changed?
      elsif @admin_session_settings.length == 1 and !@has_sa_setting.zero?
        obj = AdminSessionSetting.new(
            client_id: @client_id,
            session_inactivity_timeout: super_admin_session_timeout,
            mfa_frequency: super_admin_mfa_frequency,
            last_acted_by: @admin_id,
            status: GlobalConstant::AdminSessionSetting.active_status,
            log_sync: true,
            source: GlobalConstant::AdminActivityChangeLogger.web_source
        )
        obj.send("set_#{GlobalConstant::Admin.super_admin_role}")
        obj.save!

        admin_setting_obj.session_inactivity_timeout = admin_session_timeout
        admin_setting_obj.mfa_frequency = admin_mfa_frequency
        admin_setting_obj.source = GlobalConstant::AdminActivityChangeLogger.web_source
        admin_setting_obj.log_sync = true
        admin_setting_obj.admin_types = 0
        admin_setting_obj.send("set_#{GlobalConstant::Admin.normal_admin_role}")
        admin_setting_obj.save! if admin_setting_obj.changed?
      elsif @admin_session_settings.length == 1 and @has_sa_setting.zero?
        admin_setting_obj.session_inactivity_timeout = admin_session_timeout
        admin_setting_obj.mfa_frequency = admin_mfa_frequency
        admin_setting_obj.source = GlobalConstant::AdminActivityChangeLogger.web_source
        admin_setting_obj.log_sync = true
        admin_setting_obj.save! if admin_setting_obj.changed?
      else
        super_admin_setting_obj.status = GlobalConstant::AdminSessionSetting.deleted_status
        super_admin_setting_obj.source = GlobalConstant::AdminActivityChangeLogger.web_source
        super_admin_setting_obj.log_sync = true
        super_admin_setting_obj.save! if super_admin_setting_obj.changed?

        admin_setting_obj.session_inactivity_timeout = admin_session_timeout
        admin_setting_obj.mfa_frequency = admin_mfa_frequency
        admin_setting_obj.source = GlobalConstant::AdminActivityChangeLogger.web_source
        admin_setting_obj.admin_types = 0
        admin_setting_obj.log_sync = true
        AdminSessionSetting.admin_types_config.map {|at, _| admin_setting_obj.send("set_#{at.to_s}")}
        admin_setting_obj.save! if admin_setting_obj.changed?
      end
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
      admins = Admin.where(default_client_id: @client_id)
      if @has_sa_setting.zero?
        admins.update_all(session_inactivity_timeout: @admin_setting[:session_timeout].to_i.hours.to_i)
      else
        admins.all.each do |admin|
          if admin.role == GlobalConstant::Admin.normal_admin_role
            admin.session_inactivity_timeout = @admin_setting[:session_timeout].to_i.hours.to_i
          else
            admin.session_inactivity_timeout = @super_admin_setting[:session_timeout].to_i.hours.to_i
          end
          admin.save! if admin.changed?
        end
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
    def is_valid_mfa_frequency(setting)
      if setting[:mfa_frequency].to_i < GlobalConstant::AdminSessionSetting.default_mfa_frequency ||
          setting[:mfa_frequency].to_i > GlobalConstant::AdminSessionSetting.max_mfa_frequency_value
        return false
      end
      true
    end

    # Is Valid Mfa Frequency
    #
    # * Author: Tejas
    # * Date: 07/02/2019
    # * Reviewed By:
    #
    # @return [Boolean]
    #
    def is_valid_session_inactivity_timeout(setting)
      if setting[:session_timeout].to_i < GlobalConstant::AdminSessionSetting.min_session_inactivity_timeout ||
          setting[:session_timeout].to_i > GlobalConstant::AdminSessionSetting.max_session_inactivity_timeout
        return false
      end
      true
    end

  end
end
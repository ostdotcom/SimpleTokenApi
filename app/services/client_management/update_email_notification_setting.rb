module ClientManagement

  class UpdateEmailNotificationSetting < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 24/01/2019
    # * Reviewed By:
    #
    # @param [Integer] client_id (mandatory) -  client id
    # @param [Integer] admin_id (mandatory) -  admin id
    # @param [hash] email_setting (mandatory) -  email settings with notification types and the admin ids subscribed to it
    #
    # @return [ClientManagement::UpdateEmailNotificationSetting]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @admin_id = @params[:admin_id]
      @email_setting = params[:email_setting]

      @admins = []
      @super_admins, @normal_admins = {}, {}
    end

    # Perform
    #
    # * Author: Aman
    # * Date: 24/01/2019
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform
      r = validate_and_sanitize
      return r unless r.success?

      fetch_admins

      r = validate_email_settings
      return r unless r.success?

      update_admins

      success
    end

    private

    # Validate And Sanitize
    #
    # * Author: Aman
    # * Date: 24/01/2019
    # * Reviewed By:
    #
    # @return [Result::Base]
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
    # * Author: Aman
    # * Date: 24/01/2019
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    # Sets @client, @admin
    #
    def validate_client_and_admin

      r = fetch_and_validate_client
      return r unless r.success?

      r = fetch_and_validate_admin
      return r unless r.success?

      success
    end

    # Fetch Client Plan
    #
    # * Author: Aman
    # * Date: 24/01/2019
    # * Reviewed By:
    #
    # sets @admins, @normal_admins, @super_admins
    #
    def fetch_admins
      @admins = Admin.get_all_admins_from_memcache(@client_id)

      @admins.each do |admin|
        if admin.role == GlobalConstant::Admin.super_admin_role
          @super_admins[admin.id] = admin
        else
          @normal_admins[admin.id] = admin
        end
      end

    end

    # Validate Email settings
    #
    # * Author: Aman
    # * Date: 24/01/2019
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_email_settings
      params_error_data = {}
      super_admin_ids = @super_admins.keys
      all_admin_ids = @normal_admins.keys + super_admin_ids

      all_admins_in_setting = @email_setting.values.flatten.uniq

      return error_with_identifier('invalid_api_params',
                                   'cm_uens_ves_1',
                                   [],
                                   'Admins do not exist'
      ) if (all_admins_in_setting - all_admin_ids).present?

      GlobalConstant::Admin.notification_types_config.each do |n_type, data|
        if data[:super_admin_mandatory] && (super_admin_ids - @email_setting[n_type.to_s]).present?
          params_error_data[n_type.to_sym] = 'Super Admins are Mandatory for this notification'
        end
      end

      return error_with_identifier('invalid_api_params',
                                   'cm_uens_ves_2',
                                   [],
                                   'There were some errors in your setttings',
                                   params_error_data
      ) if params_error_data.present?

      success
    end

    # Update admin notification types
    #
    # * Author: Aman
    # * Date: 24/01/2019
    # * Reviewed By:
    #
    def update_admins

      GlobalConstant::Admin.notification_types_config.each do |n_type, data|
        include_admin_ids = @email_setting[n_type.to_s]

        @admins.each do |admin|
          if include_admin_ids.include?(admin.id)
            admin.send("set_#{n_type.to_s}")
          else
            admin.send("unset_#{n_type.to_s}")
          end
        end

      end

      @admins.each do |admin|
        admin.save! if admin.changed?
      end

    end


  end
end


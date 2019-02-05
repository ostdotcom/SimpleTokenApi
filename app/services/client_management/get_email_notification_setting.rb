module ClientManagement

  class GetEmailNotificationSetting < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 24/01/2019
    # * Reviewed By:
    #
    # @param [Integer] client_id (mandatory) -  client id
    # @param [Integer] admin_id (mandatory) -  admin id
    #
    # @return [ClientManagement::GetEmailNotificationSetting]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @admin_id = @params[:admin_id]

      @admins = []
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

      success_with_data(success_response_data)
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

    # Fetch Admins
    #
    # * Author: Aman
    # * Date: 24/01/2019
    # * Reviewed By:
    #
    # sets @admins
    #
    def fetch_admins
      @admins = Admin.get_all_admins_from_memcache(@client_id)
    end

    # Api response data
    #
    # * Author: Aman
    # * Date: 24/01/2019
    # * Reviewed By:
    #
    # returns [Hash] api response data
    #
    def success_response_data
      admin_details = {}
      super_admins_data = {}
      normal_admins_data = {}
      admin_names = []
      sorted_super_admin_ids = []
      sorted_normal_admin_ids = []
      group_email_setting_data = {}

      Admin.notification_types_config.each do |n_type, _|
        group_email_setting_data[n_type.to_sym] = []
      end

      @admins.each do |admin|
        admin_details[admin.id] = admin.get_hash
        sanitized_admin_name = admin.name.to_s.downcase
        admin_names << sanitized_admin_name

        admin.notification_types_array.each do |n_type|
          group_email_setting_data[n_type.to_sym] << admin.id
        end

        if admin.role == GlobalConstant::Admin.super_admin_role
          super_admins_data[sanitized_admin_name] ||= []
          super_admins_data[sanitized_admin_name] << admin.id
        else
          normal_admins_data[sanitized_admin_name] ||= []
          normal_admins_data[sanitized_admin_name] << admin.id
        end
      end

      admin_names = admin_names.sort.uniq

      admin_names.each do |name|
        sanitized_admin_name = name.to_s.downcase
        sorted_super_admin_ids += (super_admins_data[sanitized_admin_name] || []).sort
        sorted_normal_admin_ids += (normal_admins_data[sanitized_admin_name] || []).sort
      end
      order = sorted_super_admin_ids + sorted_normal_admin_ids
      sections = []

      GlobalConstant::Admin.notification_types_config.each do |notification_type, data|

        next if (!@client.is_whitelist_setup_done? &&
            (notification_type.to_s == GlobalConstant::Admin.whitelisting_balance_alert_notification_type))

        next if (!@client.is_web_host_setup_done? && !@client.is_whitelist_setup_done? &&
            (notification_type.to_s == GlobalConstant::Admin.contract_address_update_notification_type))

        checked = group_email_setting_data[notification_type.to_sym]
        disabled = data[:super_admin_mandatory] ? sorted_super_admin_ids : []
        section = {
            display_text: data[:display_text],
            checked: checked,
            disabled: disabled,
            order: order,
            data_keyname: notification_type.to_s
        }
        sections << section
      end

      {
          section: sections,
          admins: admin_details
      }
    end

  end
end


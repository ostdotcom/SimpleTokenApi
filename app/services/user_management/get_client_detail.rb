module UserManagement

  class GetClientDetail < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @param [Integer] client_id (mandatory) - client id
    # @params [String] template_type (mandatory) - this is the page template name
    #
    # @return [UserManagement::GetClientDetail]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @template_type = @params[:template_type]

      @client = nil
      @client_setting = nil
      @page_setting = nil
    end

    # Perform
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def perform
      r = validate_and_sanitize
      return r unless r.success?

      r = fetch_and_validate_client
      return r unless r.success?

      r = validate_client_details
      return r unless r.success?

      r = fetch_client_settings
      return r unless r.success?

      r = fetch_page_settings
      return r unless r.success?

      success_with_data(response_data)
    end

    private

    # validate and sanitize params data
    #
    # * Author: Aman
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_and_sanitize
      @template_type = @template_type.to_s.strip

      r = super
      return r unless r.success?

      return error_with_data(
          'um_gcd_1',
          'Invalid Template Type',
          'Invalid Template Type',
          GlobalConstant::ErrorAction.default,
          {}
      ) if [
          GlobalConstant::ClientTemplate.login_template_type,
          GlobalConstant::ClientTemplate.sign_up_template_type,
          GlobalConstant::ClientTemplate.reset_password_template_type,
          GlobalConstant::ClientTemplate.change_password_template_type,
          GlobalConstant::ClientTemplate.token_sale_blocked_region_template_type
      ].exclude?(@template_type)

      success
    end

    # validate clients web hosting setup details
    #
    # * Author: Aman
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # Sets @client
    #
    # @return [Result::Base]
    #
    def validate_client_details
      return error_with_data(
          'um_gbd_1',
          'Client is not active',
          'Client is not active',
          GlobalConstant::ErrorAction.default,
          {}
      ) if !@client.is_web_host_setup_done?

      success
    end

    # Fetch clients Sale setting data
    #
    # * Author: Aman
    # * Date: 08/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def fetch_client_settings
      r = ClientManagement::GetClientSetting.new(client_id: @client_id).perform
      return r unless r.success?

      @client_setting = r.data

      success
    end

    # Fetch clients page setting data
    #
    # * Author: Aman
    # * Date: 08/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def fetch_page_settings
      r = page_setting_class.new(client_id: @client_id).perform
      return r unless r.success?

      @page_setting = r.data
      success
    end

    def page_setting_class
      case @template_type
        when GlobalConstant::ClientTemplate.login_template_type
          ClientManagement::PageSetting::Login
        when GlobalConstant::ClientTemplate.sign_up_template_type
          ClientManagement::PageSetting::SignUp
        when GlobalConstant::ClientTemplate.reset_password_template_type
          ClientManagement::PageSetting::ResetPassword
        when GlobalConstant::ClientTemplate.change_password_template_type
          ClientManagement::PageSetting::ChangePassword
        when GlobalConstant::ClientTemplate.token_sale_blocked_region_template_type
          ClientManagement::PageSetting::TokenSaleBlockedRegion
        else
          'invalid template type'
      end
    end

    # User detail
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Hash] hash of client settings data
    #
    def response_data
      {
          client_setting: @client_setting,
          page_setting: @page_setting
      }
    end

  end

end
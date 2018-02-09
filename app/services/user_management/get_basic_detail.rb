module UserManagement

  class GetBasicDetail < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @param [Integer] client_id (mandatory) - client id
    # @params [Integer] user_id (mandatory) - this is the user id
    # @params [String] template_type (optional) - this is the page template name
    #
    # @return [UserManagement::GetBasicDetail]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @user_id = @params[:user_id]
      @template_type = @params[:template_type]

      @client = nil
      @user = nil
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

      fetch_user

      r = fetch_client_settings
      return r unless r.success?

      r = fetch_page_settings
      return r unless r.success?

      success_with_data(success_responnse)
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

      r = validate
      return r unless r.success?

      return error_with_data(
          'um_gbd_1',
          'Invalid Template Type',
          'Invalid Template Type',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @template_type.present? && [GlobalConstant::ClientTemplate.kyc_template_type].exclude?(@template_type)

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

    # Fetch User
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # Sets @user
    #
    def fetch_user
      @user = User.get_from_memcache(@user_id)
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
      return success if @template_type.blank?
      r = ClientManagement::PageSetting::Kyc.new(client_id: @client_id).perform
      return r unless r.success?

      @page_setting = r.data
      success
    end

    # User detail
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Hash] hash of user data
    #
    def user_data
      {
          id: @user.id,
          email: @user.email,
          user_token_sale_state: @user.get_token_sale_state_page_name,
          bt_name: @user.bt_name.to_s
      }
    end

    # Success response
    #
    # * Author: Aman
    # * Date: 12/02/2018
    # * Reviewed By:
    #
    # @return [Hash] hash of result
    #
    def success_responnse
      {
          user: user_data,
          client_setting: @client_setting,
          page_setting: @page_setting
      }
    end

  end

end
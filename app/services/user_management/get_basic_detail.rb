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
    # @params [String] token (optional) - this is the double opt in token
    #
    # @return [UserManagement::GetBasicDetail]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @user_id = @params[:user_id]
      @template_type = @params[:template_type]
      @token = @params[:token]

      @token_invalid = false
      @account_activated = false
      @user_token_sale_state = nil
      @client = nil
      @user = nil
      @client_setting_data = {}
      @has_double_opt_in = false
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

      r = validate_user
      return r unless r.success?

      r = validate_user_state
      # dont return error if token is wrong.. user token sale state wont change and thus he will be redirected to verify page in web
      # return r unless r.success?

      r = fetch_client_setting_data_from_cache
      return r unless r.success?

      success_with_data(success_response)
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
      ) if @template_type.present? && [GlobalConstant::EntityGroupDraft.kyc_entity_type,
                                       GlobalConstant::EntityGroupDraft.verification_entity_type].exclude?(@template_type)

      success
    end

    # validate and check for double opt in
    #
    # * Author: Aman
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # Sets @token_invalid
    # @return [Result::Base]
    #
    def validate_user_state
      if @user.properties_array.include?(GlobalConstant::User.token_sale_double_optin_mail_sent_property) &&
          @template_type == GlobalConstant::EntityGroupDraft.kyc_entity_type

        @has_double_opt_in = true

        r = validate_token

        unless r.success?
          @token_invalid = true
          return r
        end
      end

      success
    end

    # validate user
    #
    # * Author: Aman
    # * Date: 02/05/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_user
      return unauthorized_access_response('um_gbd_vu_1') if @user.blank? || (@user.client_id != @client_id)
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

    # Validate token
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By:
    #
    # Sets @account_activated
    #
    # @return [Result::Base]
    #
    def validate_token
      return success if @token.blank?

      service_response = UserManagement::DoubleOptIn.new({t: @token, user_id: @user_id}).perform
      return unauthorized_access_response('um_gbd_2') unless service_response.success?
      @user.reload

      @account_activated = true if (@user_token_sale_state != @user.get_token_sale_state_page_name &&
          @user_token_sale_state == GlobalConstant::User.get_token_sale_state_page_names("verification_page"))

      @user_token_sale_state = @user.get_token_sale_state_page_name
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
      @user_token_sale_state = @user.get_token_sale_state_page_name
    end

    # Fetch clients setting and page setting data from cache
    #
    # * Author: Aman
    # * Date: 15/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def fetch_client_setting_data_from_cache
      return success if @template_type.blank?

      r = ClientSetting.new(@client_id, @template_type).perform
      return r unless r.success?

      @client_setting_data = r.data
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
          user_token_sale_state: @user_token_sale_state,
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
    def success_response
      {
          is_token_invalid: @token_invalid.to_i,
          account_activated: @account_activated.to_i,
          has_double_opt_in: @has_double_opt_in.to_i,
          user: user_data
      }.merge(@client_setting_data)
    end

  end

end
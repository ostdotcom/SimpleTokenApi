module UserManagement

  class VerifyCookie < ServicesBase

    # Initialize
    #
    # * Author: Kedar
    # * Date: 10/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @param [String] cookie_value (mandatory) - this is the user cookie value
    # @param [String] browser_user_agent (mandatory) - browser user agent
    #
    # @return [UserManagement::VerifyCookie]
    #
    def initialize(params)
      super

      @cookie_value = @params[:cookie_value]
      @browser_user_agent = @params[:browser_user_agent]

      @user_id = nil
      @created_ts = nil
      @token = nil

      @user = nil
      @user_secret = nil
      @extended_cookie_value = nil
      @user_token_sale_state = nil
    end

    # Perform
    #
    # * Author: Kedar
    # * Date: 10/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [Result::Base]
    #
    def perform
      r = validate
      return r unless r.success?

      r = set_parts
      return r unless r.success?

      r = validate_token
      return r unless r.success?

      set_user_token_sale_state

      set_extended_cookie_value

      success_with_data(
          user_id: @user_id,
          extended_cookie_value: @extended_cookie_value,
          user_token_sale_state: @user_token_sale_state
      )

    end

    private

    # Set parts
    #
    # * Author: Kedar
    # * Date: 10/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # Sets @user_id, @created_ts, @token
    #
    # @return [Result::Base]
    #
    def set_parts
      parts = @cookie_value.split(':')
      return unauthorized_access_response('um_vc_1') unless parts.length == 4

      return unauthorized_access_response('um_vc_2') unless parts[2] == GlobalConstant::Cookie.double_auth_prefix

      @user_id = parts[0].to_i
      return unauthorized_access_response('um_vc_3') unless @user_id > 0

      @created_ts = parts[1].to_i
      return unauthorized_access_response('um_vc_4') unless (@created_ts + 1.hour.to_i) >= Time.now.to_i

      @token = parts[3]

      success
    end

    # Validate token
    #
    # * Author: Kedar
    # * Date: 10/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # Sets @user, @user_secret
    #
    # @return [Result::Base]
    #
    def validate_token
      # TODO: Cache user object
      @user = User.where(id: @user_id).first
      return unauthorized_access_response('um_vc_5') unless @user.present? &&
          (@user[:status] == GlobalConstant::User.active_status)

      @user_secret = UserSecret.where(id: @user[:user_secret_id]).first
      return unauthorized_access_response('um_vc_6') unless @user_secret.present?

      evaluated_token = User.get_cookie_token(@user_id, @user[:password], @browser_user_agent, @created_ts)
      return unauthorized_access_response('um_vc_7') unless (evaluated_token == @token)

      success
    end

    # Set User Last State
    #
    # * Author: Aman
    # * Date: 13/10/2017
    # * Reviewed By: Sunil
    #
    # @Sets @user_token_sale_state
    #
    def set_user_token_sale_state
      @user_token_sale_state = if @user.properties_array.include?(GlobalConstant::User.token_sale_double_optin_done_property)
                      GlobalConstant::User.token_sale_double_optin_done_property # "profile_page"
                    elsif @user.properties_array.include?(GlobalConstant::User.token_sale_bt_done_property)
                      GlobalConstant::User.token_sale_bt_done_property  # "do_double_opt_in_page"
                    elsif @user.properties_array.include?(GlobalConstant::User.token_sale_kyc_submitted_property)
                      GlobalConstant::User.token_sale_kyc_submitted_property  # "bt_page"
                    else
                      nil # "kyc_page"
                    end
    end

    # Set Extened Cookie Value
    #
    # * Author: Kedar
    # * Date: 10/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @Sets @extended_cookie_value
    #
    def set_extended_cookie_value
      return if (@created_ts + 2.minute.to_i) >= Time.now.to_i
      @extended_cookie_value = User.get_cookie_value(@user_id, @user[:password], @browser_user_agent)
    end

    # Unauthorized access response
    #
    # * Author: Kedar
    # * Date: 11/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [Result::Base]
    #
    def unauthorized_access_response(err, display_text = 'Unauthorized access. Please login again.')
      error_with_data(
          err,
          display_text,
          display_text,
          GlobalConstant::ErrorAction.default,
          {}
      )
    end

  end

end
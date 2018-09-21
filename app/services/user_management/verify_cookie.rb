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
    # @param [Integer] client_id (mandatory) - client id
    #
    # @return [UserManagement::VerifyCookie]
    #
    def initialize(params)
      super

      @cookie_value = @params[:cookie_value]
      @browser_user_agent = @params[:browser_user_agent]
      @client_id = @params[:client_id]

      @user_id = nil
      @created_ts = nil
      @token = nil

      @user = nil
      @extended_cookie_value = nil
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

      set_extended_cookie_value

      success_with_data(
          user_id: @user_id,
          extended_cookie_value: @extended_cookie_value
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
      return unauthorized_access_response('um_vc_4') unless (@created_ts + GlobalConstant::Cookie.user_expiry.to_i) >= Time.now.to_i

      @token = parts[3]

      success
    end

    # Validate token
    #
    # * Author: Kedar
    # * Date: 10/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # Sets @user
    #
    # @return [Result::Base]
    #
    def validate_token
      @user = User.get_from_memcache(@user_id)
      return unauthorized_access_response('um_vc_5') unless @user.present? && @user.password.present? &&
          (@user[:status] == GlobalConstant::User.active_status) && @user.client_id == @client_id

      return unauthorized_access_response('um_vc_6') if (@user.last_logged_in_at.to_i > @created_ts)

      evaluated_token = User.get_cookie_token(@user_id, @user[:password], @browser_user_agent, @created_ts)
      return unauthorized_access_response('um_vc_7') unless (evaluated_token == @token)

      success
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
      #return if (@created_ts + 29.days.to_i) >= Time.now.to_i
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
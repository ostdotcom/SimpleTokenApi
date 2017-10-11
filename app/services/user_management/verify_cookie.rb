module UserManagement

  class VerifyCookie < ServicesBase

    # Initialize
    #
    # * Author: Kedar
    # * Date: 10/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @param [String] cookie_value (mandatory) - this is the admin cookie value
    #
    # @return [UserManagement::VerifyCookie]
    #
    def initialize(params)
      super

      @cookie_value = @params[:cookie_value]
    end

    # Perform
    #
    # * Author: Kedar
    # * Date: 10/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [AdminManagement::VerifyCookie]
    #
    def perform
      r = validate
      return r unless r.success?

      r = set_parts
      return r unless r.success?

      r = validate_token
      return r unless r.success?

      success_with_data(user_id: @user_id)

    end

    private

    # Set parts
    #
    # * Author: Kedar
    # * Date: 10/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # Sets @user_id, @current_ts, @token
    #
    # @return [Result::Base]
    #
    def set_parts
      parts = @cookie_value.split(':')
      return unauthorized_access_response('um_vc_1') unless parts.length == 4

      return unauthorized_access_response('um_vc_2') unless parts[2] == 'd'

      @user_id = parts[0].to_i
      return unauthorized_access_response('um_vc_3') unless @user_id > 0

      @current_ts = parts[1].to_i
      @token = parts[3]

      success
    end

    # Validate token
    #
    # * Author: Kedar
    # * Date: 10/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [Result::Base]
    #
    def validate_token
      user = User.where(id: @user_id).first
      return unauthorized_access_response('um_vc_4') unless user.present? &&
        (user.status == GlobalConstant::User.active_status)

      evaluated_token = User.cookie_token(@user_id, user.password, user.user_secret_id, @current_ts)
      return unauthorized_access_response('um_vc_5') unless (evaluated_token == @token)

      success
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
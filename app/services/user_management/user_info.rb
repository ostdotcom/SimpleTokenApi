module UserManagement

  class UserInfo < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By:
    #
    # @param [String] cookie_value (mandatory) - this is the Cookie recieved entered
    #
    # @return [UserManagement::UserInfo]
    #
    def initialize(params)
      super
      @cookie_value = @params[:cookie_value]

      @user_state = "logged_out"
    end

    # Perform
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform
      check_cookie
      success_with_data(user_state: @user_state)
    end

    private

    # Set parts
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By:
    #
    # Sets @user_id, @current_ts, @token
    #
    # @return [Result::Base]
    #
    def check_cookie
      parts = @cookie_value.split(':')
      return if (parts.length != 4) || (parts[2] != 'd') || (parts[0].to_i <= 0)

      user_id = parts[0].to_i
      current_ts = parts[1].to_i
      token = parts[3]

      user = User.where(id: user_id).first
      return if user.blank? || (user.status != GlobalConstant::User.active_status)

      evaluated_token = User.cookie_token(user_id, user.password, user.user_secret_id, current_ts)
      return if (evaluated_token != token)

      @user_state = get_user_state(user)
      success
    end


    def get_user_state(user)

     return 'optin_done' if user.properties_array.include?(GlobalConstant::User.token_sale_double_optin_done_property)

     return 'bt_done' if user.properties_array.include?(GlobalConstant::User.token_sale_bt_done_property)

     return 'kyc_submit_done' if user.first_name.present?

     return 'kyc_submit_pending'

    end

  end

end
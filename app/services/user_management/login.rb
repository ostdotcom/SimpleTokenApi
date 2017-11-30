module UserManagement

  class Login < ServicesBase

    # Initialize
    #
    # * Author: Kedar
    # * Date: 11/10/2017
    # * Reviewed By: Sunil
    #
    # @params [String] email (mandatory) - this is the email entered
    # @params [String] password (mandatory) - this is the password entered
    # @params [String] browser_user_agent (mandatory) - browser user agent
    # @params [String] ip_address (mandatory) - ip_address
    # @params [String] g_recaptcha_response (mandatory) - google captcha
    #
    # @return [UserManagement::Login]
    #
    def initialize(params)
      super

      @email = @params[:email]
      @password = @params[:password]
      @browser_user_agent = @params[:browser_user_agent]
      @ip_address = @params[:ip_address]
      @g_recaptcha_response = @params[:g_recaptcha_response]

      @user_secret = nil
      @user = nil
      @login_salt_d = nil
    end

    # Perform
    #
    # * Author: Kedar
    # * Date: 11/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def perform

      r = validate
      return r unless r.success?

      Rails.logger.info('---- check_recaptcha_before_verification started')
      r = check_recaptcha_before_verification
      return r unless r.success?
      Rails.logger.info('---- check_recaptcha_before_verification done')

      r = fetch_user
      return r unless r.success?

      r = decrypt_login_salt
      return r unless r.success?

      r = validate_password
      return r unless r.success?

      enqueue_job

      set_cookie_value

    end

    private

    # Verify recaptcha
    #
    # * Author: Kedar
    # * Date: 10/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def check_recaptcha_before_verification
      # Check re-capcha on when verification is not yet done
      r = Recaptcha::Verify.new({
                                    'response' => @g_recaptcha_response.to_s,
                                    'remoteip' => @ip_address.to_s
                                }).perform
      Rails.logger.info('---- Recaptcha::Verify done')
      return r unless r.success?

      success
    end

    # Fetch user
    #
    # * Author: Kedar
    # * Date: 11/10/2017
    # * Reviewed By: Sunil
    #
    # Sets @user, @user_secret
    #
    # @return [Result::Base]
    #
    def fetch_user
      @user = User.where(email: @email).first
      return unauthorized_access_response('um_l_1') unless @user.present? &&
          (@user.status == GlobalConstant::User.active_status)

      return error_with_data(
          'um_l_4',
          'The token sale ended, this account was not activated during the sale.',
          'The token sale ended, this account was not activated during the sale.',
          GlobalConstant::ErrorAction.default,
          {},
          {}
      ) if GlobalConstant::TokenSale.is_general_sale_ended? && !@user.send("#{GlobalConstant::User.token_sale_double_optin_done_property}?")



      @user_secret = UserSecret.where(id: @user.user_secret_id).first
      return unauthorized_access_response('um_l_2') unless @user_secret.present?

      success
    end

    # Decrypt login salt
    #
    # * Author: Kedar
    # * Date: 11/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def decrypt_login_salt
      r = Aws::Kms.new('login','user').decrypt(@user_secret.login_salt)
      return r unless r.success?

      @login_salt_d = r.data[:plaintext]

      success
    end

    # Validate password
    #
    # * Author: Kedar
    # * Date: 11/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def validate_password

      evaluated_password_e = User.get_encrypted_password(@password, @login_salt_d)
      return unauthorized_access_response('um_l_3') unless (evaluated_password_e == @user.password)

      success
    end

    # Do remaining task in sidekiq
    #
    # * Author: Aman
    # * Date: 23/10/2017
    # * Reviewed By:
    #
    def enqueue_job
      BgJob.enqueue(
          UserActivityLogJob,
          {
              user_id: @user.id,
              action:   GlobalConstant::UserActivityLog.login_action,
              action_timestamp: Time.now.to_i,
              extra_data: {
                  browser_user_agent: @browser_user_agent,
                  ip_address: @ip_address
              }

          }
      )
    end

    # Set cookie value
    #
    # * Author: Kedar
    # * Date: 11/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def set_cookie_value
      cookie_value = User.get_cookie_value(@user.id, @user.password, @browser_user_agent)

      success_with_data(cookie_value: cookie_value, user_token_sale_state: @user.get_token_sale_state_page_name)
    end

    # Unauthorized access response
    #
    # * Author: Kedar
    # * Date: 11/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def unauthorized_access_response(err, display_text = 'Incorrect login details.')
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
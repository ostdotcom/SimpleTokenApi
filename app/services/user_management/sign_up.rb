module UserManagement

  class SignUp < ServicesBase

    # Initialize
    #
    # * Author: Kedar
    # * Date: 11/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @params [String] email (mandatory) - this is the email entered
    # @params [String] password (mandatory) - this is the password entered
    # @params [String] browser_user_agent (mandatory) - browser user agent
    # @params [String] ip_address (mandatory) - ip_address
    # @params [String] g_recaptcha_response (mandatory) - google captcha
    # @params [String] geoip_country (optional) - geoip_country
    # @params [Hash] utm_params (optional) - Utm Parameters for latest landing page if present
    #
    # @return [UserManagement::SignUp]
    #
    def initialize(params)
      super

      @email = @params[:email]
      @password = @params[:password]
      @browser_user_agent = @params[:browser_user_agent]
      @ip_address = @params[:ip_address]
      @geoip_country = @params[:geoip_country]
      @g_recaptcha_response = @params[:g_recaptcha_response]

      @utm_params = @params[:utm_params]

      @login_salt_hash = nil
      @user_secret = nil
      @user = nil
    end

    # Perform
    #
    # * Author: Kedar
    # * Date: 11/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?

      Rails.logger.info('---- check_recaptcha_before_verification started')
      r = check_recaptcha_before_verification
      return r unless r.success?
      Rails.logger.info('---- check_recaptcha_before_verification done')

      r = check_if_email_already_registered
      return r unless r.success?

      r = generate_login_salt
      return r unless r.success?

      create_user

      enqueue_job

      set_cookie_value

    end

    private

    # Validate and sanitize
    #
    # * Author: Kedar
    # * Date: 11/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [Result::Base]
    #
    def validate_and_sanitize

      return error_with_data(
          'um_su_3',
          'Token Sale Has Ended',
          '',
          GlobalConstant::ErrorAction.default,
          {},
          {}
      ) if GlobalConstant::TokenSale.is_general_sale_ended?

      @email = @email.to_s.downcase.strip

      validation_errors = {}
      if !Util::CommonValidator.is_valid_email?(@email)
        validation_errors[:email] = 'Please enter a valid email address'
      end

      if @password.length < 8
        validation_errors[:password] = 'Password should be minimum 8 characters'
      end

      return error_with_data(
          'um_su_1',
          'Registration Error',
          '',
          GlobalConstant::ErrorAction.default,
          {},
          validation_errors
      ) if validation_errors.present?

      # NOTE: To be on safe side, check for generic errors as well
      r = validate
      return r unless r.success?

      success
    end

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

    # Check if email already registered
    #
    # * Author: Kedar
    # * Date: 11/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @return [Result::Base]
    #
    def check_if_email_already_registered
      user = User.where(email: @email).first

      return error_with_data(
          'um_su_2',
          'Registration Error',
          '',
          GlobalConstant::ErrorAction.default,
          {},
          {email: 'Email address is already registered'}
      ) if user.present?

      success
    end

    # Generate login salt
    #
    # * Author: Kedar
    # * Date: 11/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # Sets @login_salt_hash
    #
    # @return [Result::Base]
    #
    def generate_login_salt
      r = Aws::Kms.new('login', 'user').generate_data_key
      return r unless r.success?

      @login_salt_hash = r.data

      success
    end

    # Create user
    #
    # * Author: Kedar
    # * Date: 11/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # Sets @user_secret, @user
    #
    # @return [Result::Base]
    #
    def create_user
      # first insert into user_secrets and use it's id in users table
      @user_secret = UserSecret.create!(login_salt: @login_salt_hash[:ciphertext_blob])

      password_e = User.get_encrypted_password(@password, @login_salt_hash[:plaintext])

      @user = User.create!(
          email: @email,
          password: password_e,
          user_secret_id: @user_secret.id,
          status: GlobalConstant::User.active_status
      )
    end

    # Do remaining task in sidekiq
    #
    # * Author: Aman
    # * Date: 20/10/2017
    # * Reviewed By: Sunil
    #
    def enqueue_job
      BgJob.enqueue(
          NewUserRegisterJob,
          {
              user_id: @user.id,
              utm_params: @utm_params,
              ip_address: @ip_address,
              browser_user_agent: @browser_user_agent,
              geoip_country: @geoip_country
          }
      )
    end

    # Set cookie value
    #
    # * Author: Kedar
    # * Date: 11/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # Sets @cookie_value
    #
    # @return [Result::Base]
    #
    def set_cookie_value
      cookie_value = User.get_cookie_value(@user.id, @user.password, @browser_user_agent)
      success_with_data(cookie_value: cookie_value)
    end

  end

end

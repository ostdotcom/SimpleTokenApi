module UserManagement

  class SignUp < ServicesBase

    # Initialize
    #
    # * Author: Kedar
    # * Date: 11/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @param [String] email (mandatory) - this is the email entered
    # @param [String] password (mandatory) - this is the password entered
    # @param [String] browser_user_agent (mandatory) - browser user agent
    #
    # @return [UserManagement::SignUp]
    #
    def initialize(params)
      super

      @email = @params[:email]
      @password = @params[:password]
      @browser_user_agent = @params[:browser_user_agent]

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

      r = check_if_email_already_registered
      return r unless r.success?

      r = generate_login_salt
      return r unless r.success?

      create_user

      set_cookie_value

    end

    private

    def validate_and_sanitize
      @email.to_s.downcase.strip!

      r = validate
      return r unless r.success?

      return error_with_data(
          'um_su_1',
          'Invalid Email',
          'Invalid Email',
          GlobalConstant::ErrorAction.default,
          {},
          {email: "Invalid Email"}
      ) if !Util::CommonValidator.is_valid_email?(@email)

      return error_with_data(
          'um_su_1',
          'Password should be minimum 8 characters',
          'Password should be minimum 8 characters',
          GlobalConstant::ErrorAction.default,
          {},
          {password: 'Password should be minimum 8 characters'}
      ) if @password.length < 8

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
          'um_su_1',
          'User is already registered.',
          'User is already registered.',
          GlobalConstant::ErrorAction.default,
          {}
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

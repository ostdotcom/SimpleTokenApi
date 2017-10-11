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
    #
    # @return [UserManagement::SignUp]
    #
    def initialize(params)
      super

      @email = @params[:email]
      @password = @params[:password]

      @login_salt_hash = nil
      @password_e = nil
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

      r = validate
      return r unless r.success?

      r = check_if_email_already_registered
      return r unless r.success?

      r = generate_login_salt
      return r unless r.success?

      r = encrypt_password
      return r unless r.success?

      create_user

      set_cookie_value

    end

    private

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
      r = Aws::Kms.new('login','user').generate_data_key
      return r unless r.success?

      @login_salt_hash = r.data

      success
    end

    # Encrypt password
    #
    # * Author: Kedar
    # * Date: 11/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # Sets @password_e
    #
    # @return [Result::Base]
    #
    def encrypt_password
      r = LocalCipher.new(@login_salt_hash[:plaintext]).encrypt(@password)
      return r unless r.success?

      @password_e = r.data[:ciphertext_blob]

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

      @user = User.create!(
        email: @email,
        password: @password_e,
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
      cookie_value = User.cookie_value(@user, @user_secret)

      success_with_data(cookie_value: cookie_value)
    end

  end

end

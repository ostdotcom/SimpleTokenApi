module UserManagement

  class Login < ServicesBase

    # Initialize
    #
    # * Author: Kedar
    # * Date: 11/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # @param [String] email (mandatory) - this is the email entered
    # @param [String] password (mandatory) - this is the password entered
    #
    # @return [UserManagement::Login]
    #
    def initialize(params)
      super

      @email = @params[:email]
      @password = @params[:password]

      @user_secret = nil
      @user = nil
      @login_salt_d = nil
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

      r = fetch_user
      return r unless r.success?

      r = decrypt_login_salt
      return r unless r.success?

      r = validate_password
      return r unless r.success?

      set_cookie_value

    end

    private

    # Fetch user
    #
    # * Author: Kedar
    # * Date: 11/10/2017
    # * Reviewed By: Sunil Khedar
    #
    # Sets @user, @user_secret
    #
    # @return [Result::Base]
    #
    def fetch_user
      @user = User.where(email: @email).first
      return unauthorized_access_response('um_l_1') unless @user.present?

      @user_secret = UserSecret.where(id: @user.user_secret_id).first
      return unauthorized_access_response('um_l_1') unless @user_secret.present?

      success
    end

    # Decrypt login salt
    #
    # * Author: Kedar
    # * Date: 11/10/2017
    # * Reviewed By: Sunil Khedar
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
    # * Reviewed By: Sunil Khedar
    #
    # @return [Result::Base]
    #
    def validate_password
      r = LocalCipher.new(@login_salt_d).decrypt(@user.password)
      return r unless r.success?

      (r.data[:plaintext] == @password) ?
        success :
        unauthorized_access_response('um_l_2')
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
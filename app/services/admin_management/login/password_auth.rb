module AdminManagement

  module Login

    class PasswordAuth < ServicesBase

      # Initialize
      #
      # * Author: Kedar
      # * Date: 10/10/2017
      # * Reviewed By: Sunil Khedar
      #
      # @param [String] email - this is the email entered
      # @param [String] password - this is the password entered
      #
      # @return [AdminManagement::Login::PasswordAuth]
      #
      def initialize(params)
        super

        @email = @params[:email]
        @password = @params[:password]

        @admin = nil
        @admin_secret = nil
        @login_salt_d = nil
        @cookie_value = nil
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

        r = fetch_admin
        return r unless r.success?

        r = fetch_admin_secret
        return r unless r.success?

        r = decrypt_login_salt
        return r unless r.success?

        r = match_password_hash
        return r unless r.success?

        r = set_step1_cookie_val
        return r unless r.success?

        success

      end

      private

      # Fetch admin
      #
      # * Author: Kedar
      # * Date: 10/10/2017
      # * Reviewed By: Sunil Khedar
      #
      # Sets @admin
      #
      # @return [Result::Base]
      #
      def fetch_admin
        @admin = Admin.where(email: @email).first
        return incorrect_login_error('am_l_pa_1') unless @admin.present?

        success
      end

      # Fetch admin secret
      #
      # * Author: Kedar
      # * Date: 10/10/2017
      # * Reviewed By: Sunil Khedar
      #
      # Sets @admin_secret
      #
      # @return [Result::Base]
      #
      def fetch_admin_secret
        @admin_secret = AdminSecret.where(uuid: @admin.uuid).first
        return incorrect_login_error('am_l_pa_2') unless @admin_secret.present?

        success
      end

      # Decrypt login salt
      #
      # * Author: Kedar
      # * Date: 10/10/2017
      # * Reviewed By: Sunil Khedar
      #
      # Sets @login_salt_d
      #
      # @return [Result::Base]
      #
      def decrypt_login_salt
        login_salt_e = @admin_secret.login_salt
        return incorrect_login_error('am_l_pa_3') unless login_salt_e.present?

        r = Aws::Kms.new('login', 'admin').decrypt(login_salt_e)
        return r unless r.success?

        @login_salt_d = r.data[:plaintext]

        success

      end

      # Match password hash
      #
      # * Author: Kedar
      # * Date: 10/10/2017
      # * Reviewed By: Sunil Khedar
      #
      # @return [Result::Base]
      #
      def match_password_hash
        evaluated_password_e = ::Admin.get_encrypted_password(@password, @login_salt_d)
        return incorrect_login_error('am_l_pa_4') unless (evaluated_password_e == @admin.password)

        success
      end

      # Set step 1 cookie value
      #
      # * Author: Kedar
      # * Date: 10/10/2017
      # * Reviewed By: Sunil Khedar
      #
      # Sets @cookie_value
      #
      # @return [Result::Base]
      #
      def set_step1_cookie_val
        success
      end

      # Incorrect login error
      #
      # * Author: Kedar
      # * Date: 10/10/2017
      # * Reviewed By: Sunil Khedar
      #
      # @return [Result::Base]
      #
      def incorrect_login_error(err_code)
        error_with_action_and_data(
          err_code,
          'Email or passowrd entered is incorrect.',
          'Email or passowrd entered is incorrect.',
          GlobalConstant::ErrorAction.default,
          {}
        )
      end

    end

  end

end
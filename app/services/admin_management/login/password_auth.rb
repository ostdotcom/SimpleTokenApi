module AdminManagement

  module Login

    class PasswordAuth < ServicesBase

      # Initialize
      #
      # * Author: Kedar
      # * Date: 10/10/2017
      # * Reviewed By: Sunil
      #
      # @params [String] email (mandatory) - this is the email entered
      # @params [String] password (mandatory) - this is the password entered
      # @params [String] browser_user_agent (mandatory) - browser user agent
      #
      # @return [AdminManagement::Login::PasswordAuth]
      #
      def initialize(params)
        super

        @email = @params[:email]
        @password = @params[:password]
        @browser_user_agent = @params[:browser_user_agent]

        @admin = nil
        @admin_secret = nil
        @login_salt_d = nil
        @single_auth_cookie_value = nil
      end

      # Perform
      #
      # * Author: Kedar
      # * Date: 10/10/2017
      # * Reviewed By: Sunil
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

        r = set_single_auth_cookie_value
        return r unless r.success?

        success_with_data(single_auth_cookie_value: @single_auth_cookie_value)

      end

      private

      # Fetch admin
      #
      # * Author: Kedar
      # * Date: 10/10/2017
      # * Reviewed By: Sunil
      #
      # Sets @admin
      #
      # @return [Result::Base]
      #
      def fetch_admin
        @admin = Admin.where(email: @email).first
        return incorrect_login_error('am_l_pa_1') unless @admin.present? &&
            @admin.status == GlobalConstant::Admin.active_status

        success
      end

      # Fetch admin secret
      #
      # * Author: Kedar
      # * Date: 10/10/2017
      # * Reviewed By: Sunil
      #
      # Sets @admin_secret
      #
      # @return [Result::Base]
      #
      def fetch_admin_secret
        @admin_secret = AdminSecret.get_from_memcache(@admin.admin_secret_id)
        return incorrect_login_error('am_l_pa_2') unless @admin_secret.present?

        success
      end

      # Decrypt login salt
      #
      # * Author: Kedar
      # * Date: 10/10/2017
      # * Reviewed By: Sunil
      #
      # Sets @login_salt_d
      #
      # @return [Result::Base]
      #
      def decrypt_login_salt
        login_salt_e = @admin_secret.login_salt
        return incorrect_login_error('am_l_pa_3') unless login_salt_e.present?

        r = Aws::Kms.new('login', 'admin').decrypt(login_salt_e)
        return incorrect_login_error('am_l_pa_4') unless r.success?

        @login_salt_d = r.data[:plaintext]

        success

      end

      # Match password hash
      #
      # * Author: Kedar
      # * Date: 10/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Result::Base]
      #
      def match_password_hash

        evaluated_password_e = Admin.get_encrypted_password(@password, @login_salt_d)
        return incorrect_login_error('am_l_pa_5') unless (evaluated_password_e == @admin.password)

        success
      end

      # Set single auth cookie value
      #
      # * Author: Kedar
      # * Date: 10/10/2017
      # * Reviewed By: Sunil
      #
      # Sets @single_auth_cookie_value
      #
      # @return [Result::Base]
      #
      def set_single_auth_cookie_value

        @single_auth_cookie_value = Admin.get_cookie_value(
            @admin.id,
            @admin.password,
            @admin.last_otp_at,
            @browser_user_agent,
            GlobalConstant::Cookie.single_auth_prefix
        )

        success

      end

      # Incorrect login error
      #
      # * Author: Kedar
      # * Date: 10/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Result::Base]
      #
      def incorrect_login_error(err_code)
        error_with_data(
            err_code,
            'Email or password is incorrect.',
            'Email or password is incorrect.',
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

    end

  end

end
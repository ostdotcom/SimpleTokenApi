module AdminManagement

  module Profile

    class ChangePassword < ServicesBase

      # Initialize
      #
      # * Author: Aman
      # * Date: 09/01/2018
      # * Reviewed By:
      #
      # @params [String] admin_id (mandatory) - this is the email entered
      # @params [String] current_password (mandatory) - this is the current password in use
      # @params [String] new_password (mandatory) - this is the password to be updated
      # @params [String] confirm_password (mandatory) - this is to confirm the password to be updated
      # @params [String] browser_user_agent (mandatory) - browser user agent
      #
      # @return [AdminManagement::Profile::ChangePassword]
      #
      def initialize(params)
        super

        @admin_id = @params[:admin_id]
        @current_password = @params[:current_password]
        @new_password = @params[:new_password]
        @confirm_password = @params[:confirm_password]
        @browser_user_agent = @params[:browser_user_agent]

        @admin = nil
        @admin_secret = nil
        @login_salt_d = nil
        @double_auth_cookie_value = nil
      end

      # Perform
      #
      # * Author: Aman
      # * Date: 09/01/2018
      # * Reviewed By:
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

        r = match_current_password_hash
        return r unless r.success?

        update_password

        r = set_double_auth_cookie_value
        return r unless r.success?

        success_with_data(double_auth_cookie_value: @double_auth_cookie_value)

      end

      private

      # validate
      #
      # * Author: Aman
      # * Date: 09/01/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def validate
        r = super
        return r unless r.success?

        return error_with_data(
            'am_l_cp_1',
            'Change Password Error',
            '',
            GlobalConstant::ErrorAction.default,
            {},
            {confirm_password: 'Password should be minimum 8 characters'}
        ) if @confirm_password.length < 8

        return error_with_data(
            'am_l_cp_2',
            'Change Password Error',
            '',
            GlobalConstant::ErrorAction.default,
            {},
            {confirm_password: 'Passwords do not match'}
        ) if @confirm_password != @new_password

        return error_with_data(
            'am_l_cp_2.1',
            'Change Password Error',
            '',
            GlobalConstant::ErrorAction.default,
            {},
            {confirm_password: 'Please enter a different password'}
        ) if @current_password == @new_password

        success
      end

      # Fetch admin
      #
      # * Author: Aman
      # * Date: 09/01/2018
      # * Reviewed By:
      #
      # Sets @admin
      #
      # @return [Result::Base]
      #
      def fetch_admin
        @admin = Admin.get_from_memcache(@admin_id)
        return incorrect_login_error('am_l_cp_3') unless @admin.present?

        success
      end

      # Fetch admin secret
      #
      # * Author: Aman
      # * Date: 09/01/2018
      # * Reviewed By:
      #
      # Sets @admin_secret
      #
      # @return [Result::Base]
      #
      def fetch_admin_secret
        @admin_secret = AdminSecret.get_from_memcache(@admin.admin_secret_id)
        return incorrect_login_error('am_l_cp_4') unless @admin_secret.present?

        success
      end

      # Decrypt login salt
      #
      # * Author: Aman
      # * Date: 09/01/2018
      # * Reviewed By:
      #
      # Sets @login_salt_d
      #
      # @return [Result::Base]
      #
      def decrypt_login_salt
        login_salt_e = @admin_secret.login_salt
        return incorrect_login_error('am_l_cp_5') unless login_salt_e.present?

        r = Aws::Kms.new('login', 'admin').decrypt(login_salt_e)
        return incorrect_login_error('am_l_cp_6') unless r.success?

        @login_salt_d = r.data[:plaintext]

        success

      end

      # Match password hash
      #
      # * Author: Aman
      # * Date: 09/01/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def match_current_password_hash

        evaluated_password_e = Admin.get_encrypted_password(@current_password, @login_salt_d)

        return error_with_data(
            'am_l_cp_7',
            'Change Password Error',
            '',
            GlobalConstant::ErrorAction.default,
            {},
            {current_password: 'Invalid Password'}
        ) unless (evaluated_password_e == @admin.password)

        success
      end

      # Update Password Hash of Admin
      #
      # * Author: Aman
      # * Date: 09/01/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def update_password
        @admin.password = Admin.get_encrypted_password(@new_password, @login_salt_d)
        @admin.save!
      end

      # Set Double auth cookie
      #
      # * Author: Aman
      # * Date: 10/10/2017
      # * Reviewed By: Sunil
      #
      # Sets @double_auth_cookie_value
      #
      # @return [Result::Base]
      #
      def set_double_auth_cookie_value
        @double_auth_cookie_value = Admin.get_cookie_value(
            @admin.id,
            @admin.password,
            @admin.last_otp_at,
            @browser_user_agent,
            GlobalConstant::Cookie.double_auth_prefix
        )

        success
      end

      # Incorrect login error
      #
      # * Author: Aman
      # * Date: 09/01/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def incorrect_login_error(err_code)
        error_with_data(
            err_code,
            'Invalid Details',
            'Invalid Details',
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

    end

  end

end
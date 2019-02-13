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
      # @params [String] ip_address (mandatory) - ip_address
      #
      # @params [String] mfa_session_cookie_value (optional) - mfa session auth cookie value
      # @params [String] next_url (optional) - relative url to redirect on login
      #
      # @return [AdminManagement::Login::PasswordAuth]
      #
      def initialize(params)
        super

        @email = @params[:email]
        @password = @params[:password]
        @browser_user_agent = @params[:browser_user_agent]
        @ip_address = @params[:ip_address]

        @mfa_session_cookie_value = @params[:mfa_session_cookie_value]
        @next_url = @params[:next_url] || ""

        @has_valid_mfa_session = false
        @admin = nil
        @admin_secret = nil
        @login_salt_d = nil
        @admin_auth_cookie_value = nil


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

        check_mfa_session_and_set_cookie

        r = set_admin_auth_cookie_value
        return r unless r.success?

        success_with_data(
            mfa_session_cookie_value: @mfa_session_cookie_value,
            admin_auth_cookie_value: @admin_auth_cookie_value,
            redirect_url: redirect_url
        )

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

        return incorrect_login_error('is_deleted') if @admin.present? &&
            @admin.status == GlobalConstant::Admin.deleted_status

        return incorrect_login_error('am_l_pa_2') unless @admin.present? &&
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

      # Check the MFA Session and set cookie accordingly
      #
      # * Author: Kedar
      # * Date: 10/10/2017
      # * Reviewed By: Sunil
      #
      # Sets
      #
      # @return [Result::Base]
      #
      def check_mfa_session_and_set_cookie
        if !Util::CommonValidateAndSanitize.is_hash?(@mfa_session_cookie_value)
          @mfa_session_cookie_value = {}
          return
        end

        mfa_session_key = MfaLog.get_mfa_session_key(@admin.id, @ip_address, @browser_user_agent)
        mfa_session_value = @mfa_session_cookie_value[mfa_session_key]

        return if mfa_session_value.blank?

        parts = mfa_session_value.split(':')

        if parts.length != 3
          @mfa_session_cookie_value.delete(mfa_session_key)
          return
        end


        mfa_log_id = parts[0].to_i
        token = parts[1]
        last_mfa_time = parts[2].to_i

        mfa_log = MfaLog.where(id: mfa_log_id).first

        if mfa_log.blank? || (mfa_log.admin_id != @admin.id) || (mfa_log.ip_address != @ip_address) ||
            (mfa_log.browser_user_agent != @browser_user_agent) || (mfa_log.last_mfa_time.to_i != last_mfa_time) ||
            (mfa_log.token != token) || (mfa_log.status != GlobalConstant::MfaLog.active_status)

          @mfa_session_cookie_value.delete(mfa_session_key)
          return
        end


        ar = AdminSessionSetting.is_active
        ar = (@admin.role == GlobalConstant::Admin.super_admin_role) ? ar.is_super_admin : ar.is_normal_admin
        admin_setting = ar.where(client_id: @admin.default_client_id).first

        if (last_mfa_time + admin_setting.mfa_frequency) <= Time.now.to_i
          mfa_log.status = GlobalConstant::MfaLog.deleted_status
          mfa_log.save!
          @mfa_session_cookie_value.delete(mfa_session_key)
          return
        end


        mfa_log.token = SecureRandom.hex
        mfa_log.save!
        @mfa_session_cookie_value[mfa_session_key] = mfa_log.get_mfa_session_value

        @has_valid_mfa_session = true
      end


      # Set single auth cookie value
      #
      # * Author: Kedar
      # * Date: 10/10/2017
      # * Reviewed By: Sunil
      #
      # Sets @admin_auth_cookie_value
      #
      # @return [Result::Base]
      #
      def set_admin_auth_cookie_value

        if @has_valid_mfa_session

          @admin_auth_cookie_value = Admin.get_cookie_value(
              @admin.id,
              @admin.password,
              @admin.last_otp_at,
              @browser_user_agent,
              GlobalConstant::Cookie.double_auth_prefix
          )
        else
          @admin_auth_cookie_value = Admin.get_cookie_value(
              @admin.id,
              @admin.password,
              @admin.last_otp_at,
              @browser_user_agent,
              GlobalConstant::Cookie.single_auth_prefix
          )
        end

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

      # Set returns redirect url
      #
      # * Author: Aman
      # * Date: 17/01/2019
      # * Reviewed By:
      #
      #
      # @return [String]
      #
      def redirect_url
        if @next_url.present?
          @next_url = CGI.unescape(@next_url)
          @next_url = nil if !ValidateLink.is_valid_redirect_path?(@next_url)
        end

        if !@has_valid_mfa_session
          next_url_param = @next_url.present? ? "next=#{@next_url}" : nil
          GlobalConstant::WebUrls.multifactor_auth + next_url_param
        else
          @admin.has_accepted_terms_of_use? ? get_application_url : GlobalConstant::WebUrls.terms_and_conditions
        end
      end

      # Set redirect url
      #
      # * Author: Aman
      # * Date: 17/01/2019
      # * Reviewed By:
      #
      #
      # @return [String]
      #
      def get_application_url
        @next_url.present? ? @next_url : GlobalConstant::WebUrls.admin_dashboard
      end

    end

  end

end
module AdminManagement

  module Login

    class MultifactorAuth < ServicesBase

      # Initialize
      #
      # * Author: Aman
      # * Date: 10/10/2017
      # * Reviewed By: Sunil
      #
      # @params [String] single_auth_cookie_value (mandatory) - single auth cookie value
      # @params [String] otp (mandatory) - this is the Otp entered
      # @params [String] browser_user_agent (mandatory) - browser user agent
      #
      # @return [AdminManagement::Login::MultifactorAuth]
      #
      def initialize(params)

        super

        @single_auth_cookie_value = @params[:single_auth_cookie_value].to_s
        @otp = @params[:otp].to_s
        @browser_user_agent = @params[:browser_user_agent]

        @double_auth_cookie_value = nil

        @admin_id = nil
        @admin = nil
        @admin_secret = nil
        @login_salt_d = nil
        @ga_secret_d = nil

      end

      # Perform
      #
      # * Author: Aman
      # * Date: 10/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Result::Base]
      #
      def perform

        r = validate
        return r unless r.success?

        r = validate_single_auth_cookie
        return r unless r.success?

        r = fetch_admin
        return r unless r.success?

        r = fetch_admin_secret
        return r unless r.success?

        r = decrypt_login_salt
        return r unless r.success?

        r = decrypt_ga_secret
        return r unless r.success?

        r = validate_otp
        return r unless r.success?

        r = set_double_auth_cookie_value
        return r unless r.success?

        success_with_data(
            double_auth_cookie_value: @double_auth_cookie_value
        )
      end

      private

      # Parse and validate single auth cookie
      #
      # * Author: Aman
      # * Date: 10/10/2017
      # * Reviewed By: Sunil Khedar
      #
      # Sets @admin_id
      #
      # @return [Result::Base]
      #
      def validate_single_auth_cookie

        service_response = AdminManagement::VerifyCookie::SingleAuth.new(
          cookie_value: @single_auth_cookie_value,
          browser_user_agent: @browser_user_agent
        ).perform

        return unauthorized_access_response('am_l_ma_1') unless service_response.success?

        @admin_id = service_response.data[:admin_id]

        success
      end

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
        @admin = Admin.where(id: @admin_id).first
        return incorrect_login_error('am_l_ma_2') unless @admin.present?

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
        @admin_secret = AdminSecret.where(id: @admin.admin_secret_id).first
        return unauthorized_access_response('am_l_ma_3') unless @admin_secret.present?

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
        return unauthorized_access_response('am_l_ma_4') unless login_salt_e.present?

        r = Aws::Kms.new('login', 'admin').decrypt(login_salt_e)
        return unauthorized_access_response('am_l_ma_5') unless r.success?

        @login_salt_d = r.data[:plaintext]

        success
      end

      # Decrypt ga secret
      #
      # * Author: Aman
      # * Date: 10/10/2017
      # * Reviewed By: Sunil Khedar
      #
      # Sets @ga_secret_d
      #
      # @return [Result::Base]
      #
      def decrypt_ga_secret

        decryptor_obj = LocalCipher.new(@login_salt_d)

        resp = decryptor_obj.decrypt(@admin_secret.ga_secret)
        return unauthorized_access_response('am_l_ma_6') unless resp.success?

        @ga_secret_d = resp.data[:plaintext]

        success
      end

      # Validate otp
      #
      # * Author: Aman
      # * Date: 10/10/2017
      # * Reviewed By: Sunil Khedar
      #
      # @return [Result::Base]
      #
      def validate_otp
        rotp_obj = TimeBasedOtp.new(@ga_secret_d)
        r = rotp_obj.verify_with_drift_and_prior(@otp, @admin.last_otp_at)
        return error_with_data(
            'am_l_ma_7',
            'Invalid Otp',
            '',
            GlobalConstant::ErrorAction.default,
            {otp: 'Invalid Otp'}
        ) unless r.success?

        # Update last_otp_at
        @admin.last_otp_at = r.data[:verified_at_timestamp]
        @admin.save!(validate: false)

        success
      end

      # Set Double auth cookie
      #
      # * Author: Aman
      # * Date: 10/10/2017
      # * Reviewed By: Sunil Khedar
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

      # Error Response
      #
      # * Author: Aman
      # * Date: 10/10/2017
      # * Reviewed By: Sunil Khedar
      #
      # @return [Result::Base]
      #
      def unauthorized_access_response(err, display_text = 'Unauthorized access. Please login again.')
        r = error_with_data(
          err,
          display_text,
          display_text,
          GlobalConstant::ErrorAction.default,
          {}
        )
        r.http_code = GlobalConstant::ErrorCode.unauthorized_access
        r
      end

    end

  end

end
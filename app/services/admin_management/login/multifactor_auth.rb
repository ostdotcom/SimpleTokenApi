module AdminManagement

  module Login

    class MultifactorAuth < ServicesBase

      EXPIRY_INTERVAL = 15.minutes

      # Initialize
      #
      # * Author: Aman
      # * Date: 10/10/2017
      # * Reviewed By:
      #
      # @param [String] step_1_cookie_value (mandatory) - this is the step1_cookie_value entered
      # @param [String] otp (mandatory) - this is the Otp entered
      #
      # @return [AdminManagement::Login::MultifactorAuth]
      #
      def initialize(params)
        super

        @step_1_cookie_value = @params[:step_1_cookie_value].to_s
        @otp = @params[:otp].to_s

        @step2_cookie_value = nil
        @admin_id = nil
      end

      # Perform
      #
      # * Author: Aman
      # * Date: 10/10/2017
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform
        r = validate
        return r unless r.success?

        r = parse_and_validate_cookie
        return r unless r.success?

        r = validate_otp
        return r unless r.success?

        r = set_step2_cookie_value
        return r unless r.success?

        success_with_data(
            step_2_cookie_value: @step_2_cookie_value
        )
      end

      private

      # Parse and validate step1 cookie
      #
      # * Author: Aman
      # * Date: 10/10/2017
      # * Reviewed By:
      #
      # @return [Result::Base]
      # Sets @admin_id, @cookie_timestamp
      #
      def parse_and_validate_cookie

        cookie_parts = @step_1_cookie_value.try(:split, ":")

        return unauthorized_access_response('al_m_la_1') if cookie_parts.length != 4
        return unauthorized_access_response('al_m_la_2') if cookie_parts[2] != 's'

        @admin_id = cookie_parts[0].to_i
        @cookie_timestamp = cookie_parts[1].to_i
        token = cookie_parts[3]

        return unauthorized_access_response('al_m_la_3') if @cookie_timestamp < (Time.now.to_i - EXPIRY_INTERVAL.to_i)

        r = fetch_admin_step1_cookie_token
        return r unless r.success?

        return unauthorized_access_response('al_m_la_4') if token != r.data[:step1_cookie_token]

        success
      end

      # fetch admin step1 token
      #
      # * Author: Aman
      # * Date: 10/10/2017
      # * Reviewed By:
      #
      # @return [Result::Base]
      # Sets @admin, @admin_secret
      #
      def fetch_admin_step1_cookie_token

        @admin = Admin.where(id: @admin_id).first
        return unauthorized_access_response('al_m_la_5') if @admin.blank?

        @admin_secrets = @admin.admin_secret
        return unauthorized_access_response('al_m_la_5') if @admin_secrets.blank?

        step1_cookie_token = Digest::MD5.hexdigest(
            "#{@admin.id}:#{@admin.password}:#{@admin.udid}:#{@cookie_timestamp}:s"
        )

        success_with_data(
            step1_cookie_token: step1_cookie_token
        )
      end

      # Validate otp
      #
      # * Author: Aman
      # * Date: 10/10/2017
      # * Reviewed By:
      #
      # @return [Result::Base]
      # Sets last_otp_at of admin secrets
      #
      def validate_otp
        return unauthorized_access_response('al_m_la_6') if login_salt_d.blank? || ga_secret_d.blank?
        rotp_obj = Rotp::Totp.new(ga_secret_d)
        r = rotp_obj.verify_with_drift_and_prior(@otp, @admin_secrets.last_otp_at)
        return r unless r.success?

        @admin_secrets.last_otp_at = r.data[:verified_at_timestamp]
        @admin_secrets.save!(validate: false)
        success
      end

      # Set Step2 cookie
      #
      # * Author: Aman
      # * Date: 10/10/2017
      # * Reviewed By:
      #
      # @return [Result::Base]
      # Sets @step2_cookie_value
      #
      def set_step2_cookie_value
        current_ts = Time.now.to_i
        token_e = Digest::MD5.hexdigest(
            "#{@admin.id}:#{@admin.password}:#{@admin.udid}:#{current_ts}:d:#{@admin_secrets.ga_secret}"
        )

        @step2_cookie_value = "#{@admin.id}:#{current_ts}:d:#{token_e}"

        success
      end

      # Fetch login_salt_d
      #
      # * Author: Aman
      # * Date: 10/10/2017
      # * Reviewed By:
      #
      # @return [String] Decrypted Login Salt
      #
      def login_salt_d
        @login_salt_d ||= begin
          kms_obj = Aws::Kms.new('login', 'admin')
          resp = kms_obj.decrypt(@admin_secrets.login_salt)
          resp.success? ? resp.data[:plaintext] : ''
        end
      end

      # Fetch ga_secret_d
      #
      # * Author: Aman
      # * Date: 10/10/2017
      # * Reviewed By:
      #
      # @return [String] Decrypted Ga Secret key
      #
      def ga_secret_d
        @ga_secret_d ||= begin
          decryptor_obj = LocalCipher.new(login_salt_d)
          resp = decryptor_obj.decrypt(@admin_secrets.ga_secret)
          resp.success? ? resp.data[:plaintext] : ''
        end
      end

      # Error Response
      #
      # * Author: Aman
      # * Date: 10/10/2017
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def unauthorized_access_response(err, display_text = 'Unauthorized access. Please login again.')
        error_with_action_and_data(
          err,
          display_text,
          display_text,
          GlobalConstant::ErrorAction.default,
          {}
        )
      end

    end

  end

end
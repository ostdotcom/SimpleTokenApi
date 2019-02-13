module AdminManagement

  module Login

    module Multifactor

      class Authenticate < AdminManagement::Login::Multifactor::Base

        # Initialize
        #
        # * Author: Aman
        # * Date: 10/10/2017
        # * Reviewed By: Sunil
        #
        # @params [String] single_auth_cookie_value (mandatory) - single auth cookie value
        # @params [String] otp (mandatory) - this is the Otp entered
        # @params [String] browser_user_agent (mandatory) - browser user agent
        # @params [String] ip_address (mandatory) - browser user agent
        #
        # @params [String] mfa_session_cookie_value (optional) - mfa session auth cookie value
        # @params [String] next_url (optional) - relative url to redirect on login
        #
        # @return [AdminManagement::Login::Multifactor::Authenticate]
        #
        def initialize(params)
          super

          @otp = @params[:otp].to_s
          @ip_address = @params[:ip_address]

          @mfa_session_cookie_value = @params[:mfa_session_cookie_value]
          @next_url = @params[:next_url] || ""
          @double_auth_cookie_value = nil
          @mfa_log = nil
          @token = nil
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

          r = create_entry_in_mfa_log
          return r unless r.success?

          r = set_mfa_session_cookie
          return r unless r.success?

          success_with_data(
              double_auth_cookie_value: @double_auth_cookie_value,
              mfa_session_cookie_value: @mfa_session_cookie_value,
              redirect_url: redirect_url
          )
        end

        private

        # Validate otp
        #
        # * Author: Aman
        # * Date: 10/10/2017
        # * Reviewed By: Sunil
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
              {},
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

        # create_entry_in_mfa_log
        #
        # * Author: Tejas
        # * Date: 05/02/2019
        # * Reviewed By:
        #
        # @return [String]
        #
        def create_entry_in_mfa_log
          @token = SecureRandom.hex

          @mfa_log = MfaLog.create!(admin_id: @admin.id,
                                    ip_address: @ip_address,
                                    browser_user_agent: @browser_user_agent,
                                    status: GlobalConstant::MfaLog.active_status,
                                    token: @token,
                                    last_mfa_time: Time.now.to_i)
          success
        end

        # Set Last 2fa Login Time Cookie
        #
        # * Author: Tejas
        # * Date: 05/02/2019
        # * Reviewed By:
        #
        # Sets @mfa_session_cookie_value
        #
        # @return [Result::Base]
        #
        def set_mfa_session_cookie

          if !Util::CommonValidateAndSanitize.is_hash?(@mfa_session_cookie_value)
            @mfa_session_cookie_value = {}
          end

          @mfa_session_cookie_value[@mfa_log.session_key] = @mfa_log.get_mfa_session_value

          success
        end

        # Set returns redirect url
        #
        # * Author: Mayur
        # * Date: 17/01/2019
        # * Reviewed By:
        #
        #
        # @return [String]
        #
        def redirect_url
          @admin.has_accepted_terms_of_use? ? get_application_url : GlobalConstant::WebUrls.terms_and_conditions
        end

        # returns application_url
        #
        # * Author: Mayur
        # * Date: 17/01/2019
        # * Reviewed By:
        #
        #
        # @return [String]
        #
        def get_application_url
          @next_url = CGI.unescape @next_url
          return @next_url if @next_url.present? && ValidateLink.is_valid_redirect_path?(@next_url)
          GlobalConstant::WebUrls.admin_dashboard
        end


      end

    end
  end

end
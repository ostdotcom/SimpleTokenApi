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
        #
        # @return [AdminManagement::Login::Multifactor::Authenticate]
        #
        def initialize(params)
          super

          @otp = @params[:otp].to_s

          @double_auth_cookie_value = nil
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
              double_auth_cookie_value: @double_auth_cookie_value,
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
          @admin.has_accepted_terms_of_use? ? GlobalConstant::WebUrls.admin_dashboard : GlobalConstant::WebUrls.terms_of_use
        end

      end

    end
  end

end
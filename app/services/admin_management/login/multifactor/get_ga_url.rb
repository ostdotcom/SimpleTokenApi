module AdminManagement

  module Login

    module Multifactor

      class GetGaUrl < AdminManagement::Login::Multifactor::Base

        # Initialize
        #
        # * Author: Aman
        # * Date: 09/01/2018
        # * Reviewed By:
        #
        # @params [String] single_auth_cookie_value (mandatory) - single auth cookie value
        # @params [String] browser_user_agent (mandatory) - browser user agent
        #
        # @return [AdminManagement::Login::Multifactor::GetGaUrl]
        #
        def initialize(params)
          super

          @qr_code_url = ''
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

          r = validate_single_auth_cookie
          return r unless r.success?

          r = fetch_admin
          return r unless r.success?

          return success if @admin.last_otp_at.to_i > 0

          r = fetch_admin_secret
          return r unless r.success?

          r = decrypt_login_salt
          return r unless r.success?

          r = decrypt_ga_secret
          return r unless r.success?

          set_ga_secret_auth

          success_with_data(qr_code_url: @qr_code_url)

        end

        private

        # Set Ga Secret Auth
        #
        # * Author: Aman
        # * Date: 09/01/2018
        # * Reviewed By:
        #
        #
        def set_ga_secret_auth

          rotp_client = TimeBasedOtp.new(@ga_secret_d)
          r = rotp_client.provisioning_uri(@admin.name)
          return r unless r.success?

          otpauth = r.data[:otpauth]
          escaped_otpauth = CGI.escape(otpauth)

          # @qr_code_url = "https://www.google.com/chart?chs=200x200&chld=M|0&cht=qr&chl=#{escaped_otpauth}"
          @qr_code_url ="https://chart.googleapis.com/chart?chs=200x200&chld=M|0&cht=qr&chl=#{escaped_otpauth}"
        end

      end

    end

  end

end
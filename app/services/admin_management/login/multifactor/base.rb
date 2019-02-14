module AdminManagement

  module Login

    module Multifactor

      class Base < ServicesBase

        # Initialize
        #
        # * Author: Aman
        # * Date: 10/10/2017
        # * Reviewed By: Kedar
        #
        # @params [String] single_auth_cookie_value (mandatory) - single auth cookie value
        # @params [String] browser_user_agent (mandatory) - browser user agent
        #
        # @return [AdminManagement::Login::Multifactor::Base]
        #
        def initialize(params)

          super

          @single_auth_cookie_value = @params[:single_auth_cookie_value].to_s
          @browser_user_agent = @params[:browser_user_agent]

          @admin_id = nil
          @admin = nil
          @admin_secret = nil
          @login_salt_d = nil
          @ga_secret_d = nil

        end

        private

        # validate if mandatory parameters are present
        #
        # * Author: Aman
        # * Date: 10/10/2017
        # * Reviewed By: Kedar
        #
        # @return [Result::Base]
        #
        def validate
          return error_with_data(
              'am_l_ma_b_v_1',
              'Invalid Session',
              'Your session has expired. please refresh your page',
              GlobalConstant::ErrorAction.default,
              {}
          ) if @single_auth_cookie_value.blank?

          super
        end

        # Parse and validate single auth cookie
        #
        # * Author: Aman
        # * Date: 10/10/2017
        # * Reviewed By: Kedar
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

          return unauthorized_access_response('am_l_ma_b_1') unless service_response.success?

          @admin_id = service_response.data[:admin_id]

          success
        end

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
          @admin = Admin.get_from_memcache(@admin_id)
          return incorrect_login_error('am_l_ma_b_2') unless @admin.present?

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
          @admin_secret = AdminSecret.get_active_from_memcache(@admin.admin_secret_id)
          return unauthorized_access_response('am_l_ma_b_3') unless @admin_secret.present?

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
          return unauthorized_access_response('am_l_ma_b_4') unless login_salt_e.present?

          r = Aws::Kms.new('login', 'admin').decrypt(login_salt_e)
          return unauthorized_access_response('am_l_ma_b_5') unless r.success?

          @login_salt_d = r.data[:plaintext]

          success
        end

        # Decrypt ga secret
        #
        # * Author: Aman
        # * Date: 10/10/2017
        # * Reviewed By: Sunil
        #
        # Sets @ga_secret_d
        #
        # @return [Result::Base]
        #
        def decrypt_ga_secret

          decryptor_obj = LocalCipher.new(@login_salt_d)

          resp = decryptor_obj.decrypt(@admin_secret.ga_secret)
          return unauthorized_access_response('am_l_ma_b_6') unless resp.success?

          @ga_secret_d = resp.data[:plaintext]

          success
        end

      end

    end
  end

end
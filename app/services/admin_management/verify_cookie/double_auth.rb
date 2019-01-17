module AdminManagement

  module VerifyCookie

    class DoubleAuth < AdminManagement::VerifyCookie::Base

      # Initialize
      #
      # * Author: Kedar
      # * Date: 10/10/2017
      # * Reviewed By: Sunil Khedar
      #
      # @params [String] cookie_value (mandatory) - this is the admin cookie value
      # @params [String] browser_user_agent (mandatory) - browser user agent
      # @params [Hash] options (mandatory) - optional parameters
      #
      # @return [AdminManagement::VerifyCookie::DoubleAuth]
      #
      def initialize(params)
        super
        options = @params[:options]
        @is_super_admin_role = options[:is_super_admin_role].nil? ? false : options[:is_super_admin_role]
        @validate_terms_of_use = options[:validate_terms_of_use].nil? ? true : options[:validate_terms_of_use]
        @extended_cookie_value = nil
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

        r = super
        return r unless r.success?

        return unauthorized_access_response('am_da_1') if @is_super_admin_role && (@admin.role != GlobalConstant::Admin.super_admin_role)

        if  @validate_terms_of_use &&  !@admin.has_accepted_terms_of_use?
          err = error_with_internal_code('am_vc_p_1',
                                       'Terms of use not accepted',
                                       GlobalConstant::ErrorCode.temporary_redirect,
                                       {},
                                       {},
                                       {}
          )
          err.set_error_extra_info({redirect_url: GlobalConstant::WebUrls.terms_and_conditions})
          return err
        end

        set_extended_cookie_value
        r.data[:extended_cookie_value] = @extended_cookie_value
        r.data[:client_id] = @admin[:default_client_id]

        return r

      end

      private

      # Auth level
      #
      # * Author: Kedar
      # * Date: 10/10/2017
      # * Reviewed By: Sunil Khedar
      #
      # @return [String]
      #
      def auth_level
        GlobalConstant::Cookie.double_auth_prefix
      end

      # Valid upto
      #
      # * Author: Kedar
      # * Date: 10/10/2017
      # * Reviewed By: Sunil Khedar
      #
      # @return [Time]
      #
      def valid_upto
        GlobalConstant::Cookie.double_auth_expiry
      end

      # Set Extened Cookie Value
      #
      # * Author: Sunil Khedar
      # * Date: 10/10/2017
      # * Reviewed By:
      #
      # @Sets @extended_cookie_value
      #
      def set_extended_cookie_value
        return if (@created_ts + 2.minute.to_i) >= Time.now.to_i

        @extended_cookie_value = Admin.get_cookie_value(
            @admin_id,
            @admin[:password],
            @admin[:last_otp_at],
            @browser_user_agent,
            auth_level
        )
      end

    end

  end

end
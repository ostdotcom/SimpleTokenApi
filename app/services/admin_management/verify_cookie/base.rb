module AdminManagement

  module VerifyCookie

    class Base < ServicesBase

      # Initialize
      #
      # * Author: Kedar
      # * Date: 10/10/2017
      # * Reviewed By: Sunil Khedar
      #
      # @params [String] cookie_value (mandatory) - this is the admin cookie value
      #
      # @return [AdminManagement::VerifyCookie::Base]
      #
      def initialize(params)
        super

        @cookie_value = @params[:cookie_value]

        @admin = nil
        @admin_id = nil
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
        r = validate
        return r unless r.success?

        r = set_parts
        return r unless r.success?

        r = validate_token
        return r unless r.success?

        success_with_data(admin_id: @admin_id)

      end

      private

      # Set parts
      #
      # * Author: Kedar
      # * Date: 10/10/2017
      # * Reviewed By: Sunil Khedar
      #
      # Sets @admin_id, @created_ts, @token
      #
      # @return [Result::Base]
      #
      def set_parts
        parts = @cookie_value.split(':')
        return unauthorized_access_response('am_vc_1') unless parts.length == 4

        return unauthorized_access_response('am_vc_2') unless parts[2] == auth_level

        @admin_id = parts[0].to_i
        return unauthorized_access_response('am_vc_3') unless @admin_id > 0

        @created_ts = parts[1].to_i
        return unauthorized_access_response('am_vc_4') unless @created_ts + valid_upto >= Time.now.to_i

        @token = parts[3]

        success
      end

      # Validate token
      #
      # * Author: Kedar
      # * Date: 10/10/2017
      # * Reviewed By: Sunil Khedar
      #
      # @return [Result::Base]
      #
      def validate_token
        #TODO: Memcache this query
        @admin = Admin.where(id: @admin_id).first
        return unauthorized_access_response('am_vc_5') unless @admin.present? &&
          (@admin[:status] == GlobalConstant::Admin.active_status)

        evaluated_token = Admin.get_cookie_token(
            @admin_id,
            @admin[:password],
            @admin[:last_otp_at],
            auth_level,
            @created_ts)
        return unauthorized_access_response('am_vc_6') unless (evaluated_token == @token)

        success
      end

      # Unauthorized access response
      #
      # * Author: Kedar
      # * Date: 11/10/2017
      # * Reviewed By: Sunil Khedar
      #
      # @return [Result::Base]
      #
      def unauthorized_access_response(err, display_text = 'Unauthorized access. Please login again.')
        error_with_data(
          err,
          display_text,
          display_text,
          GlobalConstant::ErrorAction.default,
          {}
        )
      end

      # Auth level
      #
      # * Author: Kedar
      # * Date: 10/10/2017
      # * Reviewed By: Sunil Khedar
      #
      # @return [String]
      #
      def auth_level
        fail 'sub-class to implement'
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
        fail 'sub-class to implement'
      end

    end

  end

end
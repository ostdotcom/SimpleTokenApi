module UserManagement
  module Users
    class Get < ServicesBase

      # Initialize
      #
      # * Author: Aniket
      # * Date: 19/09/2018
      # * Reviewed By:
      #
      # @param [Integer] client_id (mandatory) -  client id
      # @param [Integer] id (mandatory) - user id
      #
      # Sets user
      #
      # @return [UserManagement::Users::Get]
      #
      def initialize(params)
        super

        @client_id = @params[:client_id]
        @user_id = @params[:id]

        @user = nil
      end

      # Perform
      #
      # * Author: Aniket
      # * Date: 19/09/2018
      # * Reviewed By:
      #
      def perform
        r = validate_and_sanitize
        return r unless r.success?

        success_with_data(service_response_data)
      end

      private

      # Valdiate and sanitize
      #
      # * Author: Aniket
      # * Date: 19/09/2018
      # * Reviewed By:
      #
      # Sets client
      #
      def validate_and_sanitize

        r = validate
        return r unless r.success?

        r = fetch_and_validate_client
        return r unless r.success?

        r = fetch_and_validate_user
        return r unless r.success?

        r = validate_and_sanitize_params
        return r unless r.success?

        success
      end

      # validate and sanitize params
      #
      # * Author: Aniket
      # * Date: 19/09/2018
      # * Reviewed By:
      #
      # Sets user_id
      #
      def validate_and_sanitize_params
        return error_with_identifier('invalid_api_params',
                                     'um_u_g_favu_1',
                                     ['invalid_user_id']
        )unless Util::CommonValidateAndSanitize.is_integer?(@user_id)
        @user_id = @user_id.to_i

        success
      end

      # fetch and validate user
      #
      # * Author: Aniket
      # * Date: 19/09/2018
      # * Reviewed By:
      #
      # Sets @user
      #
      def fetch_and_validate_user
        @user = User.get_from_memcache(@user_id)
        return error_with_identifier('resource_not_found',
                                     'um_u_g_favu_2',
                                     ['user_not_present']
        )if (@user.blank? || (@user.present? &&
            (@user.status != GlobalConstant::User.active_status || @user.client_id.to_i != @client_id)))

        success
      end

      # Format service response
      #
      # * Author: Aniket
      # * Date: 20/09/2018
      # * Reviewed By:
      #
      def service_response_data
        {
            user: @user
        }
      end

    end
  end
end

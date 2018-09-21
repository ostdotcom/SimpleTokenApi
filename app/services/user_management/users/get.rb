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

        success
      end


      # fetch user
      #
      # * Author: Aniket
      # * Date: 19/09/2018
      # * Reviewed By:
      #
      # Sets user
      #
      def fetch_and_validate_user
        return error_with_data(
            'um_u_g_favu_1',
            'Value for key is wrong',
            "Value for key id is wrong",
            GlobalConstant::ErrorAction.default,
            {},
            {}
        )unless Util::CommonValidateAndSanitize.is_integer?(@user_id)
        @user_id = @user_id.to_i

        @user = User.get_from_memcache(@user_id)
        puts "@user : #{@user.inspect}"
        return error_with_data(
            'um_u_g_favu_2',
            'User is not present',
            "User is not present",
            GlobalConstant::ErrorAction.default,
            {},
            {}
        )unless (@user.present? && @user.status == GlobalConstant::User.active_status && @user.client_id.to_i == @client_id)


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

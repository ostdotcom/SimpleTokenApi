module UserManagement
  module Users
    class Get < ServicesBase

      # Initialize
      #
      # * Author: Aniket
      # * Date: 19/09/2018
      # * Reviewed By:
      #
      # @param [AR] client (mandatory) - client obj
      # @param [Integer] id (mandatory) - user id
      #
      # Sets user
      #
      # @return [UserManagement::Users::Get]
      #
      def initialize(params)
        super

        @client = @params[:client]

        @id = @params[:id]

        @client_id = @client.id

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

        r = validate_and_sanitize_params
        return r unless r.success?

        r = fetch_and_validate_user
        return r unless r.success?

        success
      end

      # Validate and sanitize params
      #
      # * Author: Aniket
      # * Date: 26/09/2018
      # * Reviewed By:
      #
      def validate_and_sanitize_params
        return error_with_identifier('invalid_api_params',
                                     'um_u_g_favu_1',
                                     ['invalid_id']
        )unless Util::CommonValidateAndSanitize.is_integer?(@id)

        @id = @id.to_i

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

        @user = User.using_client_shard(client: @client).get_from_memcache(@id)
        return error_with_identifier('resource_not_found',
                                     'um_u_g_favu_2'
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
            user: @user.get_hash
        }
      end

    end
  end
end

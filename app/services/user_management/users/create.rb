module UserManagement
  module Users
    class Create < ServicesBase

      # Initialize
      #
      # * Author: Aman
      # * Date: 10/10/2017
      # * Reviewed By: Sunil Khedar
      #
      # @param [Integer] client_id (mandatory) -  client id of user
      # @param [String] email (mandatory) - email of user
      #
      # Sets user, new_user_added
      #
      # @return [UserManagement::Users::Create]
      #
      def initialize(params)
        super

        @client_id = @params[:client_id]
        @email = @params[:email]

        @user = nil
      end


      # Perform
      #
      # * Author: Aman
      # * Date: 02/01/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform
        r = validate_and_sanitize
        return r unless r.success?

        create_user

        success_with_data(service_response_data)

      end

      private

      # Validate and sanitize
      #
      # * Author: Aman
      # * Date: 02/01/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      # Sets @parsed_request_time, @url_path, @request_parameters
      #
      def validate_and_sanitize

        r = validate
        return r unless r.success?

        r = validate_email
        return r unless r.success?

        r = add_user_allowed?
        return r unless r.success?

        r = fetch_and_validate_user
        return r unless r.success?

        r = fetch_and_validate_client
        return r unless r.success?

        success
      end

      # Validate email
      #
      # * Author: Aniket
      # * Date: 20/09/2018
      # * Reviewed By:
      #
      def validate_email
        return error_with_data(
            'um_u_c_ve_1',
            'Please enter a valid email address',
            'Please enter a valid email address',
            GlobalConstant::ErrorAction.default,
            {},
            {}
        ) unless Util::CommonValidator.is_valid_email?(@email)

        success
      end

      # Checks whether client can add user on the basis of token_sale_end date
      #
      # * Author: Aniket
      # * Date: 20/09/2018
      # * Reviewed By:
      #
      def add_user_allowed?
        client_token_sale_detail = ClientTokenSaleDetail.get_from_memcache(@client_id)

        return error_with_data(
            'um_u_c_aua_1',
            'Can not add user',
            'You can not add user as token sale ended',
            GlobalConstant::ErrorAction.default,
            {},
            {}
        ) unless (client_token_sale_detail.present? && !client_token_sale_detail.has_token_sale_ended?)

        success
      end

      # Verify user is already present in db or not
      #
      # * Author: Aniket
      # * Date: 20/09/2018
      # * Reviewed By:
      #
      def fetch_and_validate_user
        @user = User.where(client_id: @client_id, email: @email).first

        return error_with_data(
            'um_u_c_ve_2',
            'User alerady present',
            "User with email #{@email} is already present",
            GlobalConstant::ErrorAction.default,
            {},
            {}
        )if @user.present?

        success
      end

      # Create user
      #
      # * Author: Aniket
      # * Date: 20/09/2018
      # * Reviewed By:
      #
      def create_user
        params = {
            client_id: @client_id,
            email: @email
        }
        @user = User.create(params)
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
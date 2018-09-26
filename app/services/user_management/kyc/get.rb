module UserManagement
  module Kyc
    class Get < ServicesBase

      # Initialize
      #
      # * Author: Tejas
      # * Date: 24/09/2018
      # * Reviewed By:
      #
      # @param [Integer] client_id (mandatory) -  client id
      # @param [Integer] id (mandatory) - user id
      #
      #
      # @return [UserManagement::Kyc::Get]
      #
      def initialize(params)
        super

        @client_id = @params[:client_id]
        @user_id = @params[:id]

        @user_kyc_detail = nil
      end

      # Perform
      #
      # * Author: Tejas
      # * Date: 24/09/2018
      # * Reviewed By:
      #
      def perform
        r = validate_and_sanitize
        return r unless r.success?

        r = fetch_and_validate_user_kyc_detail
        return r unless r.success?

        success_with_data(service_response_data)
      end

      private

      # Valdiate and sanitize
      #
      # * Author: Tejas
      # * Date: 24/09/2018
      # * Reviewed By:
      #
      # Sets client
      #
      def validate_and_sanitize

        r = validate
        return r unless r.success?

        r = fetch_and_validate_client
        return r unless r.success?

        r = validate_and_sanitize_params
        return r unless r.success?

        success
      end

      # validate and sanitize params
      #
      # * Author: Tejas
      # * Date: 24/09/2018
      # * Reviewed By:
      #
      #
      def validate_and_sanitize_params
        return error_with_data(
            'um_k_g_vasp_1',
            'Value for key is wrong',
            "Value for key id is wrong",
            GlobalConstant::ErrorAction.default,
            {},
            {}
        )unless Util::CommonValidateAndSanitize.is_integer?(@user_id)
        @user_id = @user_id.to_i

        success
      end

      # fetch and validate user kyc detail
      #
      # * Author: Tejas
      # * Date: 24/09/2018
      # * Reviewed By:
      #
      # Sets @user_kyc_detail
      #
      def fetch_and_validate_user_kyc_detail

        @user_kyc_detail = UserKycDetail.get_from_memcache(@user_id)
        return error_with_data(
            'um_k_g_favukd_1',
            'User kyc detail is not present',
            "User kyc detail is not present",
            GlobalConstant::ErrorAction.default,
            {},
            {}
        )if (@user_kyc_detail.blank? || (@user_kyc_detail.present? &&
            @user_kyc_detail.status != GlobalConstant::UserKycDetail.active_status)) &&
            (@user_kyc_detail.client_id.to_i != @client_id)


        success
      end

      # Fetch Admin
      #
      # * Author: Tejas
      # * Date: 24/09/2018
      # * Reviewed By:
      #
      # Sets @admin
      #
      def fetch_admin
        @admin = Admin.get_from_memcache(@user_kyc_detail.last_acted_by)
      end

      # Format service response
      #
      # * Author: Tejas
      # * Date: 24/09/2018
      # * Reviewed By:
      #
      def service_response_data
        {
            user_kyc_detail: @user_kyc_detail,
            admin: @admin
        }
      end

    end
  end
end

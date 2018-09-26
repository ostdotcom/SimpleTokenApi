module UserManagement
  module UserKyc
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
      # @return [UserManagement::UserKyc::Get]
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

        r = fetch_and_validate_user_extended_detail
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

        r = fetch_and_validate_client_kyc_detail_api_activations
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
            'um_uk_g_vasp_1',
            'Value for key is wrong',
            "Value for key id is wrong",
            GlobalConstant::ErrorAction.default,
            {},
            {}
        )unless Util::CommonValidateAndSanitize.is_integer?(@user_id)
        @user_id = @user_id.to_i

        success
      end

      # fetch and validate user extended detail
      #
      # * Author: Tejas
      # * Date: 24/09/2018
      # * Reviewed By:
      #
      # Sets @user_kyc_detail
      #
      def fetch_and_validate_user_extended_detail

        @user_extended_details = UserExtendedDetail.where(id: @user_id).first
        return error_with_data(
            'um_uk_g_favued_1',
            'User extended detail is not present',
            "User extended detail is not present",
            GlobalConstant::ErrorAction.default,
            {},
            {}
        )if @user_extended_details.blank?

        success
      end

      # fetch and validate client kyc detail api activations
      #
      # * Author: Tejas
      # * Date: 24/09/2018
      # * Reviewed By:
      #
      # Sets @client_kyc_detail_api_activations
      #
      def fetch_and_validate_client_kyc_detail_api_activations

        @client_kyc_detail_api_activations = ClientKycDetailApiActivation.get_last_active_kyc_detail_api_activation(@client_id)
        return error_with_data(
            'um_uk_g_favued_1',
            'User kyc detail api activations is not present',
            "User kyc detail api activations is not present",
            GlobalConstant::ErrorAction.default,
            {},
            {}
        )if @client_kyc_detail_api_activations.blank?

        success
      end

      # Format service response
      #
      # * Author: Tejas
      # * Date: 24/09/2018
      # * Reviewed By:
      #
      def service_response_data
        {
            user_kyc_detail: @user_extended_details
        }
      end

    end
  end
end

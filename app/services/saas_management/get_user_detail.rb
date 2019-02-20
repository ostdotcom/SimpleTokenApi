module SaasManagement
  class GetUserDetail < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 04/09/2018
    # * Reviewed By:
    #
    # @param [String] client_id (mandatory) - client id
    # @param [Integer] user_id (optional) - user id
    #
    # @return [SaasManagement::GetUserDetail]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @user_id = @params[:user_id].to_i

      @user = nil
      @user_kyc_detail = nil
    end


    # Perform
    #
    # * Author: Aman
    # * Date: 04/09/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?

      r = find_user
      return r unless r.success?

      fetch_user_kyc_detail

      success_with_data(success_response_data_for_client)

    end

    private

    # Validate and sanitize
    #
    # * Author: Aman
    # * Date: 04/09/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_and_sanitize
      r = validate
      return r unless r.success?

      r = fetch_and_validate_client
      return r unless r.success?

      r = validate_if_st_default_client
      return r unless r.success?

      return error_with_data(
          'sm_gud_vas_1',
          'Please enter a valid user id',
          'Please enter a valid user id',
          GlobalConstant::ErrorAction.default,
          {},
          {}
      ) if @user_id.to_i.blank?

      success
    end

    # Fetch and Validate client
    #
    # * Author: Aman
    # * Date: 04/09/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_if_st_default_client
      return error_with_data(
          'sm_gud_visdc_1',
          'unauthorized client action',
          'unauthorized client action',
          GlobalConstant::ErrorAction.default,
          {},
          {}
      ) if @client.is_st_token_sale_client?

      success
    end

    # find user
    #
    # * Author: Aman
    # * Date: 04/09/2018
    # * Reviewed By:
    #
    # Sets @user
    #
    def find_user

      @user = User.get_from_memcache(@user_id)

      return error_with_data(
          'sm_gud_fu_1',
          'Invalid user id',
          'Invalid user id',
          GlobalConstant::ErrorAction.default,
          {},
          {}
      ) if @user.blank? || @user.client_id != @client_id

      success
    end

    # Fetch User Kyc Detail
    #
    # * Author: Aman
    # * Date: 04/09/2018
    # * Reviewed By:
    #
    # Sets @user
    #
    def fetch_user_kyc_detail
      @user_kyc_detail = UserKycDetail.get_from_memcache(@user_id)
    end

    # response data on client basis
    #
    # * Author: Aman
    # * Date: 04/09/2018
    # * Reviewed By:
    #
    # @return [Hash] final success data
    #
    def success_response_data_for_client
      {
          user: user_data,
          user_kyc_data: user_kyc_data
      }
    end

    # User detail
    #
    # * Author: Aman
    # * Date: 04/09/2018
    # * Reviewed By:
    #
    # @return [Hash] hash of user data
    #
    def user_data
      {
          user_id: @user.id,
          email: @user.email
      }
    end

    # User detail
    #
    # * Author: Aman
    # * Date: 04/09/2018
    # * Reviewed By:
    #
    # @return [Hash] hash of user data
    #
    def user_kyc_data
      @user_kyc_detail.present? ?
          {
              kyc_status: kyc_status,
              admin_action_types: @user_kyc_detail.admin_action_types_array,
              whitelist_status: @user_kyc_detail.whitelist_status
          }
          :
          {}
    end

    # User Kyc Status
    #
    # * Author: Aman
    # * Date: 04/09/2018
    # * Reviewed By:
    #
    # @return [String] status of kyc
    #
    def kyc_status
      @user_kyc_detail.kyc_status
    end

  end
end
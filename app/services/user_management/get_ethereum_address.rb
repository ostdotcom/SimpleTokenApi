module UserManagement

  class GetEthereumAddress < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 27/10/2017
    # * Reviewed By: Sunil
    #
    # @params [Integer] user_id (mandatory) - this is the user id
    #
    # @return [UserManagement::GetEthereumAddress]
    #
    def initialize(params)
      super

      @user_id = @params[:user_id]

      @user_kyc_detail = nil
    end

    # Perform
    #
    # * Author: Aman
    # * Date: 27/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def perform
      r = validate
      return r unless r.success?

      fetch_user_kyc_detail

      r = validate_can_purchase
      return r unless r.success?

      success_with_data(success_response_data)
    end

    private

    # Fetch User Kyc Detail
    #
    # * Author: Aman
    # * Date: 27/10/2017
    # * Reviewed By: Sunil
    #
    # Sets @user_kyc_detail
    #
    def fetch_user_kyc_detail
      @user_kyc_detail = UserKycDetail.where(user_id: @user_id).first
    end

    # Validation for purchase
    #
    # * Author: Aman
    # * Date: 27/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def validate_can_purchase

     return error_with_data(
          'um_ea_1',
          'Unauthorized to purchase',
          'Unauthorized to purchase',
          GlobalConstant::ErrorAction.default,
          {}
      )  if !(@user_kyc_detail.present? && @user_kyc_detail.kyc_approved? && ethereum_address_whitelist_done?)

      return error_with_data(
          'um_ea_2',
          'Sale is not active',
          'Sale is not active',
          GlobalConstant::ErrorAction.default,
          {}
      )  if !is_sale_active?

      success
    end

    # is ethereum address whitelist complete
    #
    # * Author: Aman
    # * Date: 27/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Boolean]
    #
    def ethereum_address_whitelist_done?
      #TODO[:ethereum whitelist status]
      true
    end

    # Sale Start time for user
    #
    # * Author: Aman
    # * Date: 27/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Time]
    #
    def sale_start_time
      (@user_kyc_detail.token_sale_participation_phase == GlobalConstant::TokenSale.pre_sale_token_sale_phase) ? GlobalConstant::TokenSale.pre_sale_start_date : GlobalConstant::TokenSale.public_sale_start_date
    end

    # is sale active
    #
    # * Author: Aman
    # * Date: 27/10/2017
    # * Reviewed By:
    #
    # @return [Boolean]
    #
    def is_sale_active?
      (GlobalConstant::TokenSale.st_token_sale_active_status && current_time <= GlobalConstant::TokenSale.public_sale_end_date && current_time >= sale_start_time)
    end

    # is ethereum address whitelist complete
    #
    # * Author: Aman
    # * Date: 27/10/2017
    # * Reviewed By:
    #
    # @return [Boolean]
    #
    def current_time
      @current_time ||= Time.zone.now
    end

    # Success response data
    #
    # * Author: Aman
    # * Date: 12/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Hash] final success data
    #
    def success_response_data
      {
          foundation_ethereum_address: GlobalConstant::TokenSale.st_foundation_ethereum_address
      }
    end

  end

end
module UserManagement

  class CheckEthereumBalance < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 28/10/2017
    # * Reviewed By: Sunil
    #
    # @param [Integer] user_id (mandatory)
    # @param [String] user_ethereum_address (mandatory)
    #
    # @return [UserManagement::CheckEthereumBalance]
    #
    def initialize(params)
      super

      @user_id = @params[:user_id]
      @user_ethereum_address = @params[:user_ethereum_address]

      @user_kyc_detail = nil
    end

    # Perform
    #
    # * Author: Aman
    # * Date: 28/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def perform

      r = validate
      return r unless r.success?

      fetch_user_kyc_details

      r = validate_user_and_ethereum_address
      return r unless r.success?

      success_with_data(api_response)
    end

    private

    # set user kyc detail
    #
    # * Author: Aman
    # * Date: 28/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def fetch_user_kyc_details
      @user_kyc_detail = UserKycDetail.get_from_memcache(@user_id)
    end

    # Validate
    #
    # * Author: aman
    # * Date: 28/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def validate_user_and_ethereum_address

      return error_with_data(
          'um_ceb_1',
          'Invalid User',
          'Invalid User',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @user_kyc_detail.blank?

      return error_with_data(
          'um_ceb_2',
          'Your KYC verification has failed',
          'Your KYC verification has failed',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @user_kyc_detail.kyc_denied?

      return error_with_data(
          'um_ceb_3',
          'This is not the ETH address you submitted',
          'This is not the ETH address you submitted',
          GlobalConstant::ErrorAction.default,
          {}
      ) unless is_valid_ethereum_address?

      success
    end

    # validate ethereum address
    #
    # * Author: Aman
    # * Date: 29/10/2017
    # * Reviewed By: Sunil
    #
    # returns[Boolean]
    #
    def is_valid_ethereum_address?
      @user_ethereum_address = Util::CommonValidator.sanitize_ethereum_address(@user_ethereum_address)
      hashed_ethereurm_address = Md5UserExtendedDetail.get_hashed_value(@user_ethereum_address)
      user_extended_detail_ids = Md5UserExtendedDetail.where(ethereum_address: hashed_ethereurm_address).pluck(:user_extended_detail_id)
      user_extended_detail_ids.include?(@user_kyc_detail.user_extended_detail_id)
    end

    # Final API response
    #
    # * Author: Aman
    # * Date: 29/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def api_response
      {
          purchase_details: user_purchase_data
      }
    end

    # purchase data for user
    #
    # * Author: Aman
    # * Date: 09/11/2017
    # * Reviewed By: Sunil
    #
    # @return [Hash] sale data for user
    #
    def user_purchase_data
      Time.now >= sale_start_time_for_user ? get_user_sale_detail : {}
    end

    # Get user purchase data
    #
    # * Author: Aman
    # * Date: 09/11/2017
    # * Reviewed By: Sunil
    #
    # @return [Hash] sale data for user
    #
    def get_user_sale_detail
      stat_data = PurchaseLog.where(
        ethereum_address: @user_ethereum_address).
        select(' sum(ether_wei_value) as total_ether_wei_value, sum(usd_value) as total_usd_value, sum(st_wei_value) as total_simple_token_wei_value').first

      {
          total_dollars_sent: stat_data.total_usd_value.to_f.round(2),
          total_ethereum_sent: GlobalConstant::ConversionRate.wei_to_basic_unit(stat_data.total_ether_wei_value).to_s,
          simple_token_sent: GlobalConstant::ConversionRate.wei_to_basic_unit(stat_data.total_simple_token_wei_value).to_s
      }
    end

    # Sale Start time for user
    #
    # * Author: Aman
    # * Date: 09/11/2017
    # * Reviewed By:
    #
    # @return [Time]
    #
    def sale_start_time_for_user
      (@user_kyc_detail.token_sale_participation_phase == GlobalConstant::TokenSale.early_access_token_sale_phase) ?
        GlobalConstant::TokenSale.early_access_start_date :
        GlobalConstant::TokenSale.general_access_start_date
    end

  end

end

module UserManagement

  class CheckEthereumBalance < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 28/10/2017
    # * Reviewed By: Sunil
    #
    # @param [Integer] client_id (mandatory) - client id
    # @param [Integer] user_id (mandatory)
    # @param [String] user_ethereum_address (mandatory)
    #
    # @return [UserManagement::CheckEthereumBalance]
    #
    def initialize(params)
      super

      @user_id = @params[:user_id]
      @user_ethereum_address = @params[:user_ethereum_address]
      @client_id = @params[:client_id]

      @client = nil
      @client_token_sale_details = nil
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

      r = fetch_and_validate_client
      return r unless r.success?

      fetch_client_token_sale_details

      r = validate_client_details
      return r unless r.success?

      fetch_user_kyc_details

      r = validate_user_and_ethereum_address
      return r unless r.success?

      success_with_data(api_response)
    end

    private

    # Fetch token sale details
    #
    # * Author: Aman
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def fetch_client_token_sale_details
      @client_token_sale_details = ClientTokenSaleDetail.get_from_memcache(@client_id)
    end

    # validate clients web hosting setup details
    #
    # * Author: Aman
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # Sets @client
    #
    # @return [Result::Base]
    #
    def validate_client_details
      return error_with_data(
          'um_ceb_3',
          'Client is not active',
          'Client is not active',
          GlobalConstant::ErrorAction.default,
          {}
      ) if !@client.is_web_host_setup_done?

      success
    end

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
          'um_ceb_1.1',
          'Invalid action',
          'Invalid action',
          GlobalConstant::ErrorAction.default,
          {},
          {}
      ) if @client_id != GlobalConstant::TokenSale.st_token_sale_client_id

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
      @client_token_sale_details.has_token_sale_started? ? get_user_sale_detail : {}
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

      total_dollars_sent_by_user  = stat_data.total_usd_value.to_f.round(2)

      total_ethereum_sent_by_user = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(stat_data.total_ether_wei_value).to_f.round(4)
      total_ethereum_sent_by_user = total_ethereum_sent_by_user.to_i == total_ethereum_sent_by_user ? total_ethereum_sent_by_user.to_i : total_ethereum_sent_by_user

      total_simple_token_allotted_to_user = GlobalConstant::ConversionRate.wei_to_basic_unit_in_string(stat_data.total_simple_token_wei_value).to_f.round(4)
      total_simple_token_allotted_to_user = total_simple_token_allotted_to_user.to_i == total_simple_token_allotted_to_user ? total_simple_token_allotted_to_user.to_i : total_simple_token_allotted_to_user

      bonus_log = BonusTokenLog.where(ethereum_address: @user_ethereum_address).first
      total_st_bonus_for_user = bonus_log.present? ? bonus_log.total_bonus_value_in_st : 0


      {
          total_dollars_sent_by_user: total_dollars_sent_by_user,
          total_ethereum_sent_by_user: total_ethereum_sent_by_user,
          total_simple_token_allotted_to_user: total_simple_token_allotted_to_user,
          total_simple_token_bonus_to_user: total_st_bonus_for_user
      }
    end

  end

end

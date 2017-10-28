module UserManagement

  class CheckEthereumBalance < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 28/10/2017
    # * Reviewed By:
    #
    # @param [Integer] user_id (mandatory)
    # @param [String] ethereum_address (mandatory)
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
    # * Reviewed By:
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

    def fetch_user_kyc_details
      @user_kyc_detail = UserKycDetail.where(user_id: @user_id).first
    end

    # Validate
    #
    # * Author: Kedar
    # * Date: 13/10/2017
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
          'The ethereum address you entered is not registered',
          'The ethereum address you entered is not registered',
          GlobalConstant::ErrorAction.default,
          {}
      ) if get_ethereum_address != @user_ethereum_address

      success
    end

    def get_ethereum_address
      'a'
    end

    def api_response
      if show_purchase_data?
        {
            purchase_details: token_purchase_data
        }
      else
        {
            purchase_details: {}
        }
      end
    end

    def token_purchase_data
      {
          total_dollars_sent: 4535680,
          total_ethereum_sent: 1216,
          simple_token_allotted_in_ethereum: 200,
          simple_token_allotted_in_dollar:332998,
          token_to_ethereum_ratio: '1 Simple Token = 0.01 ETH'
      }
    end

    def show_purchase_data?
      false
    end

  end

end

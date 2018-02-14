module UserManagement

  class GetTokenSaleAddress < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 27/10/2017
    # * Reviewed By: Sunil
    #
    # @param [Integer] client_id (mandatory) - client id
    # @params [Integer] user_id (mandatory) - this is the user id
    #
    # @return [UserManagement::GetTokenSaleAddress]
    #
    def initialize(params)
      super

      @user_id = @params[:user_id]
      @client_id = @params[:client_id]

      @client = nil
      @client_token_sale_details = nil
      @user_kyc_detail = nil
      @token_sale_ethereum_address = nil
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

      r = fetch_and_validate_client
      return r unless r.success?

      fetch_client_token_sale_details

      fetch_user_kyc_detail

      r = validate_can_purchase
      return r unless r.success?

      r = decrypt_ethereum_deposit_address
      return r unless r.success?

      success_with_data(success_response_data)
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

    # Fetch User Kyc Detail
    #
    # * Author: Aman
    # * Date: 27/10/2017
    # * Reviewed By: Sunil
    #
    # Sets @user_kyc_detail
    #
    def fetch_user_kyc_detail
      @user_kyc_detail = UserKycDetail.get_from_memcache(@user_id)
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
          'Sale is not active',
          'Sale is not active',
          GlobalConstant::ErrorAction.default,
          {}
      ) if !@client_token_sale_details.is_token_sale_live?

      return error_with_data(
          'um_ea_2',
          'Invalid action',
          'Invalid action',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @client_token_sale_details.ethereum_deposit_address.blank?

      return error_with_data(
          'um_ea_3',
          'Unauthorized to purchase',
          'Unauthorized to purchase',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @user_kyc_detail.blank? || !@user_kyc_detail.kyc_approved? ||
          (@client.is_whitelist_setup_done? && !@user_kyc_detail.done_whitelist_status?)

      success
    end

    # Decrypt ethereum deposit address
    #
    # * Author: Aman
    # * Date: 14/02/2018
    # * Reviewed By:
    #
    # Sets @token_sale_ethereum_address
    # @return [Result::Base]
    #
    def decrypt_ethereum_deposit_address
      decryptor_obj = LocalCipher.new(GlobalConstant::SecretEncryptor.ethereum_deposit_address_secret_key)
      r = decryptor_obj.decrypt(@client_token_sale_details.ethereum_deposit_address)

      return error_with_data(
          'um_ea_4',
          'Unable to fetch deposit address',
          'Unable to fetch deposit address',
          GlobalConstant::ErrorAction.default,
          {}
      ) unless r.success?

      @token_sale_ethereum_address = r.data[:plaintext]

      success
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
          token_sale_ethereum_address: @token_sale_ethereum_address
      }
    end

  end

end
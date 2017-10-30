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
      ) if @user_kyc_detail.blank? || @user_kyc_detail.kyc_denied?

      r = get_ethereum_address
      return r unless r.success?

      return error_with_data(
          'um_ceb_2',
          'The ethereum address you entered is not registered',
          'The ethereum address you entered is not registered',
          GlobalConstant::ErrorAction.default,
          {}
      ) if r.data[:plaintext] != @user_ethereum_address

      success
    end

    # get decrypted ethereum address
    #
    # * Author: Aman
    # * Date: 29/10/2017
    # * Reviewed By: Sunil
    #
    # sets @kyc_salt_d, @use_extended_detail_id
    #
    def get_ethereum_address
      # TODO: Critical, use md5 way to get ethereum address. Create index on md5 ethereum_address
      user_extended_detail_obj = UserExtendedDetail.where(id: @user_kyc_detail.user_extended_detail_id).first
      kyc_salt_e = user_extended_detail_obj.kyc_salt

      r = Aws::Kms.new('kyc', 'admin').decrypt(kyc_salt_e)
      return err_response('um_ceb_3') unless r.success?
      kyc_salt_d = r.data[:plaintext]

      r = LocalCipher.new(kyc_salt_d).decrypt(user_extended_detail_obj.ethereum_address)
      return err_response('um_ceb_4') unless r.success?

      r
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
          purchase_details: {}
      }
    end

    #TODO:: Ethereum balance integration
    # def token_purchase_data
    #   {
    #       total_dollars_sent: 4535680,
    #       total_ethereum_sent: 1216,
    #       simple_token_allotted_in_ethereum: 200,
    #       simple_token_allotted_in_dollar: 332998,
    #       token_to_ethereum_ratio: '1 Simple Token = 0.01 ETH'
    #   }
    # end

    # Error message generator
    #
    # * Author: Aman
    # * Date: 29/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def err_response(err, display_text = 'Something Went wrong')
      error_with_data(
          err,
          display_text,
          display_text,
          GlobalConstant::ErrorAction.default,
          {}
      )
    end

  end

end

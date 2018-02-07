module ClientManagement

  class GetClientSetting < ServicesBase


    # Initialize
    #
    # * Author: Aman
    # * Date: 08/02/2018
    # * Reviewed By:
    #
    # @param [Integer] client_id (mandatory) -  client id
    #
    # @return [ClientManagement::GetClientSetting]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]

      @client = nil
      @client_token_sale_details = nil
    end

    # Perform
    #
    # * Author: Aman
    # * Date: 08/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform
      r = validate
      return r unless r.success?

      r = fetch_and_validate_client
      return r unless r.success?

      fetch_client_token_sale_details

      success_with_data(response_data)
    end

    private

    # Fetch token sale details
    #
    # * Author: Aman
    # * Date: 08/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def fetch_client_token_sale_details
      @client_token_sale_details = ClientTokenSaleDetail.get_from_memcache(@client_id)
    end

    # Client Setup details
    #
    # * Author: Aman
    # * Date: 08/02/2018
    # * Reviewed By:
    #
    # @return [Hash] hash of client's kyc setting
    #
    def response_data
      {
          is_st_token_sale_client: @client.is_st_token_sale_client?,
          is_whitelist_setup_done: @client.is_whitelist_setup_done?,
          token_sale_details: {
              sale_start_timestamp: @client_token_sale_details.sale_start_timestamp,
              sale_end_timestamp: @client_token_sale_details.sale_end_timestamp,
              has_ethereum_deposit_address: @client_token_sale_details.ethereum_deposit_address.present?
          }
      }
    end

  end
end
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
      @client_kyc_config_detail_obj = nil
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

      fetch_kyc_config_detail

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

    # fetch  client kyc config detail obj
    #
    # * Author: Tejas
    # * Date: 30/07/2018
    # * Reviewed By:
    #
    # Sets @client_kyc_config_detail_obj
    #
    def fetch_kyc_config_detail
      @client_kyc_config_detail_obj = ClientKycConfigDetail.get_from_memcache(@client_id)
    end

    # gives kyc_config_data
    #
    # * Author: Tejas
    # * Date: 30/07/2018
    # * Reviewed By:
    #
    # @return [Hash] template data for specific page
    #
    def kyc_config_data
      kyc_fields = @client_kyc_config_detail_obj.kyc_fields_array
      max_investor_proofs_allowed = kyc_fields.include?(GlobalConstant::ClientKycConfigDetail.investor_proof_files_path_kyc_field) ?
                                        GlobalConstant::ClientKycConfigDetail.max_number_of_investor_proofs_allowed : 0

      {
          kyc_fields: kyc_fields,
          residency_proof_nationalities: @client_kyc_config_detail_obj.residency_proof_nationalities,
          blacklisted_countries: @client_kyc_config_detail_obj.blacklisted_countries,
          max_investor_proofs_allowed: max_investor_proofs_allowed
      }
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
              token_name: @client_token_sale_details.token_name,
              token_symbol: @client_token_sale_details.token_symbol,
              sale_start_timestamp: @client_token_sale_details.sale_start_timestamp,
              sale_end_timestamp: @client_token_sale_details.sale_end_timestamp,
              has_ethereum_deposit_address: @client_token_sale_details.ethereum_deposit_address.present?
          },
       kyc_config_detail_data: kyc_config_data
      }
    end

  end
end
module ClientManagement

  class GetContractAddresses < ServicesBase

    # Initialize
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    # @param [Integer] client_id (mandatory) -  client id
    # @param [Integer] admin_id (mandatory) -  admin id
    #
    # @return [ClientManagement::GetContractAddresses]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @admin_id = @params[:admin_id]

      @client_token_sale_details = nil
      @client_whitelist_details = nil
      @client_plan = nil
    end

    # Perform
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform
      r = validate_and_sanitize
      return r unless r.success?

      fetch_client_plan
      fetch_client_whitelist_details
      fetch_client_token_sale_details


      success_with_data(success_response_data)
    end

    private

    # Validate And Sanitize
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By: Aman
    #
    #
    def validate_and_sanitize
      r = validate
      return r unless r.success?

      r = validate_client_and_admin
      return r unless r.success?

      success
    end

    # Client and Admin validate
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    # Sets @client, @admin
    #
    def validate_client_and_admin

      r = fetch_and_validate_client
      return r unless r.success?

      r = fetch_and_validate_admin
      return r unless r.success?

      success
    end

    # Validate Client Whitelisting
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    # sets @client_plan
    #
    def fetch_client_plan
      @client_plan = ClientPlan.get_client_plan_from_memcache(@client_id)
    end

    # Fetch Client Token Sale Details
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    # Sets @client_token_sale_details
    #
    def fetch_client_token_sale_details
      return unless @client.is_web_host_setup_done?
      @client_token_sale_details = ClientTokenSaleDetail.get_from_memcache(@client_id)
    end

    # Fetch Client Whitelist Details
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    # Sets @client_whitelist_details
    #
    def fetch_client_whitelist_details
      return unless has_whitelist_add_on
      @client_whitelist_details = ClientWhitelistDetail.get_from_memcache(@client_id)
    end

    # Get Decrypted Ethereum Deposit Address
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    # @return [String] ethereum_deposit_address_d
    #
    def get_decrypted_ethereum_deposit_address
      return nil if @client_token_sale_details.blank?

      ethereum_deposit_address = @client_token_sale_details.ethereum_deposit_address
      ethereum_deposit_address_d = nil

      if ethereum_deposit_address.present?
        encryptor_obj = LocalCipher.new(GlobalConstant::SecretEncryptor.ethereum_deposit_address_secret_key)
        r = encryptor_obj.decrypt(ethereum_deposit_address)
        fail r unless r.success?
        ethereum_deposit_address_d = r.data[:plaintext]
      end
      ethereum_deposit_address_d
    end

    # check if client has paid for whitelist functionality
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    # returns [Boolean] true if whitelist add on taken
    #
    def has_whitelist_add_on
      @has_whitelist_add_on ||= @client_plan.add_ons_array.include?(GlobalConstant::ClientPlan.whitelist_add_ons)
    end

    # Api response data
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    # returns [Hash] api response data
    #
    def success_response_data
      {
          has_whitelist_add_on: has_whitelist_add_on,
          web_host_setup_done: @client.is_web_host_setup_done?,
          ethereum_deposit_address: get_decrypted_ethereum_deposit_address,
          whitelist_contract_address: @client_whitelist_details.present? ? @client_whitelist_details.contract_address : nil,
          verified_operator_address: @client_whitelist_details.present? ? @client_whitelist_details.whitelister_address : nil
      }
    end

  end
end


module ClientManagement
  class UpdateWhitelistContractAddress < ServicesBase

    # todo: update service name

    # Initialize
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    # @param [Integer] client_id (mandatory) -  client id
    # @param [Integer] admin_id (mandatory) -  admin id
    # @param [String] contract_address (mandatory) - contract_address
    #
    # @return [ClientManagement::UpdateWhitelistContractAddress]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @admin_id = @params[:admin_id]
      @contract_address = @params[:contract_address]

      @client_whitelist_detail = nil
    end

    # Perform
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?

      create_and_update_contract_addresses

      success
    end


    # private

    # Validate And Sanitize
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    #
    def validate_and_sanitize
      r = validate
      return r unless r.success?

      r = validate_client_and_admin
      return r unless r.success?

      r = validate_contract_address
      return r unless r.success?

      success
    end

    # Client and Admin validate
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    # sets @admin, @client
    #
    def validate_client_and_admin
      r = fetch_and_validate_client
      return r unless r.success?

      r = fetch_and_validate_admin
      return r unless r.success?

      success
    end

    # Validate Contract Address
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    # sets @client_whitelist_detail, kyc_whitelist_log
    # @return [Result::Base]
    #
    def validate_contract_address

      return error_with_data(
          'cm_uca_vca_1',
          'Invalid Date',
          'There is no whitelist setup for this client',
          GlobalConstant::ErrorAction.default,
          {}
      ) if !@client.is_whitelist_setup_done?

      kyc_whitelist_log = KycWhitelistLog.where(client_id: @client_id,
                                                status: [GlobalConstant::KycWhitelistLog.pending_status,
                                                         GlobalConstant::KycWhitelistLog.done_status]).last
      return error_with_data(
          'cm_uca_vca_2',
          'Pending Whitelist status for this client',
          'There is pending Whitelist status for this client',
          GlobalConstant::ErrorAction.default,
          {}
      ) if kyc_whitelist_log.present?

      success
    end

    # Update Contract Addresses
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    #
    def create_and_update_contract_addresses
      @client_whitelist_detail = ClientWhitelistDetail.where(
          client_id: @client_id,
          status: GlobalConstant::ClientWhitelistDetail.active_status).first

      @client_whitelist_detail.status = GlobalConstant::ClientWhitelistDetail.inactive_status
      @client_whitelist_detail.save!


      ClientWhitelistDetail.create!(
          client_id: @client_id, contract_address: @contract_address,
          whitelister_address: @client_whitelist_detail.whitelister_address,
          suspension_type: @client_whitelist_detail.suspension_type,
          last_acted_by: @admin_id,
          status: GlobalConstant::ClientWhitelistDetail.active_status
      )
    end

  end
end
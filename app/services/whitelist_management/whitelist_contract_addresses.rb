module WhitelistManagement

  class WhitelistContractAddresses < ServicesBase

    # Initialize
    #
    # * Author: Aniket
    # * Date: 30/07/2018
    # * Reviewed By:
    #
    # @return [WhitelistManagement::WhitelistContractAddresses]
    #
    def initialize()
      super
    end

    def perform
      contract_addresses = get_contract_addresses

      success_with_data (contract_addresses)
    end

    private

    def get_contract_addresses
      ClientWhitelistDetail.where(status:GlobalConstant::ClientWhitelistDetail.active_status).pluck(:contract_address)
    end

  end

end


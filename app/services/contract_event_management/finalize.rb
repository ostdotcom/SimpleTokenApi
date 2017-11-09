module ContractEventManagement

  class Finalize < Base

    # initialize
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    # @return [ContractEventManagement::Transfer]
    #
    def initialize(params)
      super
    end

    # Perform
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform
      r = validate_and_fetch_contract_event
      return r unless r.success?

      # validate_ethereum_address

      update_token_sale_ended_data

      mark_contract_event_as_processed
      success
    end

    # Update token sale ended variable
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    #
    def update_token_sale_ended_data
      sale_variable_obj = SaleGlobalVariable.sale_ended.first
      sale_variable_obj.variable_data = 1
      sale_variable_obj.save!
    end

    # Event kind for contract event row
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    # @return [String]
    #
    def event_kind
      GlobalConstant::ContractEvent.finalize_kind
    end

    # Data for contract event row
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    # @return [Hash] Data for contract event obj
    #
    def data_for_contract_event
      {}
    end

  end

end
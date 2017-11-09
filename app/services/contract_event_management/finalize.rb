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
      begin
        r = validate
        return r unless r.success?

        update_token_sale_ended_data

        mark_contract_event_as_processed
        success
      rescue => e
        mark_contract_event_as_failed
        return exception_with_data(
            e,
            'cem_f_1',
            'exception in Finalize event management: ' + e.message,
            'Something went wrong.',
            GlobalConstant::ErrorAction.default,
            {contract_event_obj_id: @contract_event_obj.id}
        )
      end
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
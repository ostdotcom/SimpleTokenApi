module ContractEventManagement

  class Base < ServicesBase

    # initialize
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    # @return [ContractEventManagement::Base]
    #
    def initialize(params)
      super
      @contract_event_obj = @params[:contract_event_obj]
    end

    # mark contract event as processed
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    def mark_contract_event_as_processed
      @contract_event_obj.status = GlobalConstant::ContractEvent.processed_status
      @contract_event_obj.save!
    end

    # mark contract event as failed
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    def mark_contract_event_as_failed
      @contract_event_obj.status = GlobalConstant::ContractEvent.failed_status
      @contract_event_obj.save!
    end

  end

end
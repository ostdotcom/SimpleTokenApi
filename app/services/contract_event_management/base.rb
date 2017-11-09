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
      @contract_event_obj = params[:contract_event_obj]

      @transaction_hash = @contract_event_obj.transaction_hash.to_s
      @block_hash = @contract_event_obj.block_hash.to_s
      @event_data = @contract_event_obj.data
      @block_execution_timestamp = @contract_event_obj.block_execution_timestamp

      @contract_event_obj = nil
    end

    # mark contract event as processed
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    def mark_contract_event_as_processed
      @contract_event_obj.status == GlobalConstant::ContractEvent.processed_status
      @contract_event_obj.save!
    end

    # mark contract event as failed
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    def mark_contract_event_as_failed
      @contract_event_obj.status == GlobalConstant::ContractEvent.failed_status
      @contract_event_obj.save!
    end

    # Event kind for contract event row
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    # @return [Exception]
    #
    def perform
      fail 'Sanitize event data not specified for contract event Management'
    end


    # Event kind for contract event row
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    # @return [Exception]
    #
    def sanitize_event_data
      fail 'Sanitize event data not specified for contract event Management'
    end

    # Event kind for contract event row
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    # @return [Exception]
    #
    def event_kind
      fail 'Event kind not specified for contract event Management'
    end

    # Event data for contract event record
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    # @return [Exception]
    #
    def event_data
      fail 'Event Data not specified for contract event Management'
    end

    # # Notify devs in case of an error condition
    # #
    # # * Author:Aman
    # # * Date: 31/10/2017
    # # * Reviewed By:
    # #
    # def notify_devs(error_data)
    #   ApplicationMailer.notify(
    #       body: {transaction_hash: @transaction_hash, event_data: @event_data},
    #       data: {error_data: error_data},
    #       subject: 'Error while ContractEventManagement'
    #   ).deliver
    # end

  end

end
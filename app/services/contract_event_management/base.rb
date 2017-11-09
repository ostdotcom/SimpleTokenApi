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
      @transaction_hash = params[:transaction_hash].to_s.downcase
      @block_hash = params[:block_hash].to_s.downcase
      @event_data = params[:event_data]
      @block_execution_timestamp = params[:block_execution_timestamp]

      @contract_event_obj = nil
    end

    # Validate and check if event already processed
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    # sets @contract_event_obj
    #
    def validate_and_fetch_contract_event
      r = validate
      return r unless r.success?

      fetch_contract_event

      return error_with_data(
          'cem_b_1',
          'event is already processed',
          'event is already processed',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @contract_event_obj.present? && @contract_event_obj.status == GlobalConstant::ContractEvent.processed_status #use this status here?


      sanitize_event_data

      @contract_event_obj = create_contract_event

      success
    end

    # fetch contract event
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    # Sets @contract_event_obj
    #
    def fetch_contract_event
      @contract_event_obj = ContractEvent.where(
          transaction_hash: @transaction_hash,
          kind: event_kind
      ).first
    end

    # create an entry in contract event
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    def create_contract_event
      ContractEvent.create!({
                                block_hash: @block_hash,
                                transaction_hash: @transaction_hash,
                                kind: event_kind,
                                status: GlobalConstant::ContractEvent.unprocessed_status,
                                data: data_for_contract_event
                            })
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
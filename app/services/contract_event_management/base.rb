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
      @transaction_hash = params[:transaction_hash]
      @block_hash = params[:block_hash]
      @events_variable = params[:events_variable]

      @address = nil
      @phase = nil
    end

    # Perform
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    def perform
      r = validate
      return r unless r.success?

      sanitize_event_variables
      create_contract_event

      success
    end

    # Sanitize event_variables in an event
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    # Sets [@phase, @address]
    #
    def sanitize_event_variables
      @events_variable.each do |var_obj|

        case var_obj[:name]
          when '_account'
            @address = var_obj[:value]
          when '_phase'
            @phase = var_obj[:value]
        end
      end
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
                                data: {
                                    address: @address,
                                    phase: @phase
                                }
                            })
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
      fail 'Event kind not specified for contract_events'
    end

  end

end
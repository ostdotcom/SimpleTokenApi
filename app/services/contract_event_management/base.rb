module ContractEventManagement

  class Base < ServicesBase

    def initialize(params)
      @transacton_hash = params[:transacton_hash]
      @block_hash = params[:block_hash]
      @events_variable = params[:events_variable]

      @address = nil
      @phase = nil
    end

    def perform
      r = validate
      return r unless r.success?

      sanitize_event_variables
      create_contract_event

      success
    end

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

    def event_kind
      fail 'Event kind not specified for contract_events'
    end

  end

end
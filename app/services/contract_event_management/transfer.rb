module ContractEventManagement

  class Transfer < Base

    ETHER_TO_USD_CONVERSION_RATE = 300
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

      @address = nil
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

        sanitize_event_data

        create_purchase_log_entry

        mark_contract_event_as_processed
        success
      rescue => e
        mark_contract_event_as_failed
        return exception_with_data(
            e,
            'cem_t_1',
            'exception in transfer event management: ' + e.message,
            'Something went wrong.',
            GlobalConstant::ErrorAction.default,
            {contract_event_obj_id: @contract_event_obj.id}
        )
      end
    end

    # Create entry in payment details for ethereum
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def create_purchase_log_entry
      PurchaseLog.create!({
                              ethereum_address: @ethereum_address,
                              ether_value: @ether_value,
                              usd_value: (@ether_value * ETHER_TO_USD_CONVERSION_RATE),
                              simple_token_value: @simple_token_value,
                              purchase_date: get_purchase_date
                          })
    end

    # get rounded purchase date
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    # @return [Date] purchase date in pactific time zone
    #
    def get_purchase_date
      Time.at(@block_execution_timestamp).in_time_zone('Pacific Time (US & Canada)').to_date
    end

    # Sanitize event_variables in an event
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    # Sets [@phase, @address]
    #
    def sanitize_event_data
      @event_data.each do |var_obj|

        case var_obj[:name]
          when '_account'
            @address = var_obj[:value]
          # when '_phase'
          #   @phase = var_obj[:value]
        end
      end
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
      GlobalConstant::ContractEvent.transfer_kind
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
      {
          address: @address
      }
    end

  end

end
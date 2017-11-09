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

      @ethereum_address, @ether_value, @usd_value, @simple_token_value = nil, nil, nil, nil
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

        #validate ethereum address??

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
                              ether_value: @ether_value.to_s,
                              usd_value: @usd_value,
                              simple_token_value: @simple_token_value,
                              block_creation_timestamp: @contract_event_obj.block_creation_timestamp,
                              pst_day_start_timestamp: get_pst_rounded_purchase_date

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
    def get_pst_rounded_purchase_date
      Time.at(@contract_event_obj.block_creation_timestamp).in_time_zone('Pacific Time (US & Canada)').beginning_of_day.to_i
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
      # todo: test with big numbers
      @contract_event_obj.data.each do |var_obj|

        case var_obj[:name]
          when '_beneficiary'
            @ethereum_address = var_obj[:value].to_s
          when '_cost'
            @ether_value = var_obj[:value].to_f
            @usd_value = @ether_value * ETHER_TO_USD_CONVERSION_RATE
          when '_tokens'
            @simple_token_value = var_obj[:value].to_i
        end
      end
    end

  end

end
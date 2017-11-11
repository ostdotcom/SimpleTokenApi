module ContractEventManagement

  class Transfer < Base

    # initialize
    #
    # * Author: Aman
    # * Date: 31/10/2017
    # * Reviewed By: Kedar
    #
    # @return [ContractEventManagement::Transfer]
    #
    def initialize(params)
      super

      @block_creation_timestamp = @params[:block_creation_timestamp]

      @ethereum_address, @ether_value, @usd_value, @st_wei_value = nil, nil, nil, nil
    end

    # Perform
    #
    # * Author: Aman
    # * Date: 31/10/2017
    # * Reviewed By: Keadr
    #
    # @return [Result::Base]
    #
    def perform

      _perform do

        sanitize_event_data

        create_purchase_log_entry

      end

    end

    private

    # Sanitize event_variables in an event
    #
    # * Author: Aman
    # * Date: 31/10/2017
    # * Reviewed By: Kedar
    #
    # Sets [@ethereum_address, @ether_wei_value, @usd_value, @st_wei_value]
    #
    def sanitize_event_data
      @contract_event_obj.data[:event_data].each do |var_obj|

        case var_obj[:name]
          when '_beneficiary'
            @ethereum_address = var_obj[:value].to_s
          when '_cost'
            @ether_wei_value = var_obj[:value].to_i
          when '_tokens'
            @st_wei_value = var_obj[:value].to_i
            @usd_value = GlobalConstant::ConversionRate.st_in_wei_to_usd(@st_wei_value).round(2)
        end

      end

    end

    # Create entry in payment details for ethereum
    #
    # * Author: Aman
    # * Date: 31/10/2017
    # * Reviewed By: Kedar
    #
    # @return [Result::Base]
    #
    def create_purchase_log_entry
      PurchaseLog.create!({
                              ethereum_address: @ethereum_address,
                              ether_wei_value: @ether_wei_value,
                              usd_value: @usd_value,
                              st_wei_value: @st_wei_value,
                              block_creation_timestamp: @block_creation_timestamp,
                              pst_day_start_timestamp: get_pst_rounded_purchase_date

                          })
    end

    # get rounded purchase date
    #
    # * Author: Aman
    # * Date: 31/10/2017
    # * Reviewed By: Kedar
    #
    # @return [Date] purchase date in pactific time zone
    #
    def get_pst_rounded_purchase_date
      Time.at(@block_creation_timestamp).in_time_zone('Pacific Time (US & Canada)').beginning_of_day.to_i
    end

  end

end
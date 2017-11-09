module Crons

  class ReadBlockEvents

    include Util::ResultHelper

    SMART_CONTRACT_EVENTS = {
        '0xEc9859B0B3B4652aD5e264776a79E544b76bc447' => ['TokensPurchased', 'Finalized']
    }

    MIN_BLOCK_DIFFERENCE = 6

    #IN seconds
    BLOCK_CREATION_AVERAGE_WAIT_TIME = 15
    BLOCK_CREATION_MAX_WAIT_TIME = 25
    MIN_SLEEP_TIME = 1

    # initialize
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    # @return [Crons::ReadBlockEvents]
    #
    def initialize
      @last_processed_block_number = 0
      @current_block_number = 1

      @block_data_response = {}
      @keep_processing = true
      @sleep_interval = BLOCK_CREATION_AVERAGE_WAIT_TIME # in seconds
      @start_time = nil
      @highest_block_number = nil

      @current_block_hash, @block_execution_timestamp, @transactions = nil, nil, []
      @transaction_hash = nil
    end

    # Perform
    # How to handle execptions.What if one transaction cannot be processed
    #
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    def perform
      # @last_processed_block_number = SaleGlobalVariable.last_block_processed.first.try(:variable_data).to_i
      @last_processed_block_number = 21009

      while (@keep_processing)
        set_data_for_current_iteration

        get_block_data
        # todo: Invalid response structure.. events will be filtered and sent?
        r = validate_response
        return r unless r.success?

        if blocks_trail_count >= MIN_BLOCK_DIFFERENCE
          process_transactions
          update_last_processed_block_number
        end
        @keep_processing = false
        sleep(compute_sleep_interval)
      end

    end

    # Set Data for current iteration
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    # Sets [@current_block_number, @start_timestamp, @block_data_response, @highest_block_number,
    # @current_block_hash, @block_execution_timestamp, @transactions, @transaction_hash]
    #
    def set_data_for_current_iteration
      @current_block_number = @last_processed_block_number + 1
      @start_timestamp = Time.now.to_i
      @block_data_response = {}
      @highest_block_number = nil
      @current_block_hash, @block_execution_timestamp, @transactions = nil, nil, []
      @transaction_hash = nil
    end

    # Get block from public node
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    # Sets [@block_data_response]
    #
    def get_block_data
      Rails.logger.info("read_block_events block number: #{@current_block_number} - Making API call ReadBlockEvents")
      @block_data_response = OpsApi::Request::GetBlockInfo.new.perform(public_api_request_params)
      Rails.logger.info("read_block_events --- block number: #{@current_block_number} --- block_fetched_response: #{@block_data.inspect}")
    end

    # Gives the required params for public ops call
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    # Returns [Hash] data for get_block_data parameter
    #
    def public_api_request_params
      {
          block_number: @current_block_number
      }
    end

    # Validates Block data
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    # @return [Result::Base]
    # Sets [@transactions, @current_block_hash, @block_execution_timestamp, @highest_block_number]
    #
    def validate_response
      if @block_data_response.success?
        meta = @block_data_response.data[:meta]
        @transactions = @block_data_response.data[:transactions]

        binding.pry

        if (meta[:current_block][:block_number] != @current_block_number)
          notify_devs(@block_data_response.merge(msg: "Urgent::Block returned is invalid"))
          return error_with_data(
              'c_rbe_1',
              'invalid block returned',
              'invalid block returned',
              GlobalConstant::ErrorAction.default,
              {}
          )
        end

        @current_block_hash = meta[:current_block][:block_hash]
        @block_execution_timestamp = meta[:current_block][:timestamp]
        @highest_block_number = meta[:highest_block_number]

        success
      else
        notify_devs(@block_data_response)
        error_with_data(
            'c_rbe_2',
            'error while fetching block',
            'error while fetching block',
            GlobalConstant::ErrorAction.default,
            {}
        )
      end
    end

    # Process all transactions in a block
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    # Sets [@transaction_hash]
    #
    def process_transactions
      @transactions.each do |transaction|
        @transaction_hash = transaction[:transaction_hash]

        transaction[:events_data].each do |event|
          r = validate_event(event)
          next unless r.success?
          process_event(event)
        end
      end
    end

    # Validate event in a transaction
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    # @return [Result::Base] checks if event received is correct
    #
    def validate_event(event)
      valid_events = SMART_CONTRACT_EVENTS[event[:address]]

      return success if valid_events.present? && valid_events.includes?(event[:name])

      if valid_events.blank?
        notify_devs({transaction: transaction}.merge!(msg: "invalid event address"))
        return error_with_data(
            'c_rbe_3',
            'invalid event address',
            'invalid event address',
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

      return error_with_data(
          'c_rbe_4',
          'event is not needed',
          'event is not needed',
          GlobalConstant::ErrorAction.default,
          {}
      )
    end

    # Process an event in a transaction
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    def process_event(event)
      event_kind = get_event_kind(event[:name])

      process_event_param = {
          transacton_hash: @transacton_hash,
          block_hash: @block_hash,
          block_execution_timestamp: @block_execution_timestamp,
          event_data: event[:events]
      }

      case event_kind
        when GlobalConstant::ContractEvent.transfer_kind
          ContractEventManagement::Transfer.new(process_event_param).perform
        when GlobalConstant::ContractEvent.finalize_kind
          ContractEventManagement::Finalize.new(process_event_param).perform
      end

    end

    def get_event_kind(event_name)
      case event_name.downcase
        when 'transfer'
          GlobalConstant::ContractEvent.transfer_kind
        when 'finalize'
          GlobalConstant::ContractEvent.finalize_kind
        else
          fail 'Invalid Event Kind'
      end
    end

    # Updates last procssed block number
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    # Sets [@last_processed_block_number]
    #
    def update_last_processed_block_number
      SaleGlobalVariable.last_block_processed.update_all(variable_data: @current_block_number)
      @last_processed_block_number = @current_block_number
    end

    # Compute Sleep Interval for next iteration
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    # Returns[Integer] sleep interval in seconds
    #
    def compute_sleep_interval

      if (blocks_trail_count < MIN_BLOCK_DIFFERENCE)
        sleep_time = BLOCK_CREATION_MAX_WAIT_TIME
      elsif (blocks_trail_count > MIN_BLOCK_DIFFERENCE)
        sleep_time = MIN_SLEEP_TIME
      else # block difference is exactly equal to min needed
        sleep_time = BLOCK_CREATION_AVERAGE_WAIT_TIME - (Time.now.to_i - @start_timestamp)
        sleep_time > MIN_SLEEP_TIME ? sleep_time : MIN_SLEEP_TIME
      end

      sleep_time
    end

    def blocks_trail_count
      @highest_block_number - @current_block_number
    end

    # Notify devs in case of an error condition
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    def notify_devs(error_data)
      ApplicationMailer.notify(
          body: {current_block_number: @current_block_number},
          data: {error_data: error_data},
          subject: 'Error while ReadBlockEvents'
      ).deliver
    end

  end

end
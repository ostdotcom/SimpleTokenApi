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
      @last_processed_block_number = SaleGlobalVariable.last_block_processed.first.try(:variable_data).to_i

      @keep_processing = true
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

      # todo: @keep_processing only if needed to stop else remove

      while (@keep_processing)
        set_data_for_current_iteration

        get_block_data

        r = validate_response
        return r unless r.success?

        if blocks_trail_count >= MIN_BLOCK_DIFFERENCE
          process_transactions
          update_last_processed_block_number
        end

        # todo: sleep to be handled from continuos cron service
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
    # @current_block_hash, @block_creation_timestamp, @transactions, @transaction_hash]
    #
    def set_data_for_current_iteration
      @current_block_number = @last_processed_block_number + 1
      @start_timestamp = Time.now.to_i
      @block_data_response = {}
      @highest_block_number = nil
      @current_block_hash, @block_creation_timestamp,  = nil, nil
      @transactions, @transaction_hash = nil, []
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
      Rails.logger.info("read_block_events --- block number: #{@current_block_number} --- block_fetched_response: #{@block_data_response.inspect}")
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
    # Sets [@transactions, @current_block_hash, @block_creation_timestamp, @highest_block_number]
    #
    def validate_response
      if @block_data_response.success?
        meta = @block_data_response.data[:meta]
        @transactions = @block_data_response.data[:transactions]


        if (meta[:current_block][:block_number].to_i != @current_block_number)
          notify_dev(@block_data_response.merge(msg: "Urgent::Block returned is invalid"))
          return error_with_data(
              'c_rbe_1',
              'invalid block returned',
              'invalid block returned',
              GlobalConstant::ErrorAction.default,
              {}
          )
        end

        @current_block_hash = meta[:current_block][:block_hash]
        @block_creation_timestamp = meta[:current_block][:timestamp].to_i
        @highest_block_number = meta[:highest_block_number].to_i

        success
      else
        notify_dev(@block_data_response)
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
      # todo: downcase and check??
      valid_events = SMART_CONTRACT_EVENTS[event[:address]]

      # todo: downcase and check??
      return success if valid_events.present? && valid_events.includes?(event[:name])

      notify_dev({transaction: transaction, event: event}.merge!(msg: "invalid event address"))
      return error_with_data(
          'c_rbe_3',
          'invalid event address',
          'invalid event address',
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
      contract_event_obj = create_contract_event(event_kind, event_data)

      return if contract_event_obj.status != GlobalConstant::ContractEvent.recorded_status

      case event_kind
        when GlobalConstant::ContractEvent.transfer_kind
          ContractEventManagement::Transfer.new(contract_event_obj: contract_event_obj).perform
        when GlobalConstant::ContractEvent.finalize_kind
          ContractEventManagement::Finalize.new(contract_event_obj: contract_event_obj).perform
        else
          # skip event processing
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

    # create user_contract_event
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    def create_contract_event(event_kind, event_data)

      contract_event_obj = ContractEvent.where(
          transaction_hash: @transaction_hash,
          kind: event_kind
      ).first

      contract_event_status = GlobalConstant::ContractEvent.recorded_status

      if contract_event_obj.present?
        return contract_event_obj if contract_event_obj.block_hash.downcase == @block_hash.downcase
        contract_event_status = GlobalConstant::ContractEvent.duplicate_status
        notify_dev({transaction_hash: @transaction_hash, event_kind: event_kind, event_data: event_data, msg: 'duplicate event'})
      end

      ContractEvent.create!({
                                block_hash: @block_hash,
                                transaction_hash: @transaction_hash,
                                kind: event_kind,
                                status: contract_event_status,
                                block_creation_timestamp: @block_creation_timestamp,
                                data: event_data
                            })

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
    def notify_dev(error_data)
      ApplicationMailer.notify(
          body: {current_block_number: @current_block_number},
          data: {error_data: error_data},
          subject: 'Error while ReadBlockEvents'
      ).deliver
    end

  end

end
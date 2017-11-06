module Crons

  class ReadBlockEvents

    include Util::ResultHelper

    SMART_CONTRACT_EVENTS = {
        '516567571' => ['purchase'],
        '9890227' => ['finalize', 'transfer']
    }

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
      @sleep_interval = 15 # in seconds
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
      @last_processed_block_number = SaleGlobalVariable.last_block_processed.first.try(:variable_data).to_i

      while (@keep_processing)
        set_data_for_current_iteration

        get_block_data
        r = process_response
        return r unless r.success?

        process_transactions
        update_last_processed_block_number
        sleep(compute_sleep_interval)
      end

    end

    def set_data_for_current_iteration
      @current_block_number = @last_processed_block_number + 1
      @start_timestamp = Time.now.to_i
      @block_data_response = {}
      @highest_block_number = nil
      @current_block_hash, @block_execution_timestamp, @transactions = nil, nil, []
      @transaction_hash = nil
    end

    def update_last_processed_block_number
      SaleGlobalVariable.last_block_processed.update_all(variable_data: @current_block_number)
      @last_processed_block_number = @current_block_number
    end

    def compute_sleep_interval
      sleep_time = 15
      blocks_trail_count = @highest_block_number - @current_block_number

      if (blocks_trail_count < 6)
        sleep_time = 25
      elsif (blocks_trail_count > 6)
        sleep_time = 1
      else
        sleep_time = 15 - (Time.now.to_i - @start_timestamp)
        sleep_time > 0 ? sleep_time : 1
      end

      sleep_time
    end

    def get_block_data
      Rails.logger.info("read_block_events block number: #{@current_block_number} - Making API call ReadBlockEvents")
      @block_data_response = OpsApi::Request::GetBlockInfo.new.perform(get_token)
      Rails.logger.info("read_block_events --- block number: #{@current_block_number} --- block_fetched_response: #{@block_data.inspect}")
    end

    def get_token
      data = {block_number: @current_block_number}
      payload = {data: data}
      JWT.encode(payload, GlobalConstant::PublicOpsApi.secret_key, 'HS256')
    end

    def process_response
      if @block_data_response.success?
        meta = @block_data_response.data[:meta]
        @transactions = @block_data_response.data[:transactions]

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
            'c_rbe_1',
            'error while fetching block',
            'error while fetching block',
            GlobalConstant::ErrorAction.default,
            {}
        )
      end
    end


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

    def process_event(event)
      process_event_param = {
          transacton_hash: @transacton_hash,
          block_hash: @block_hash,
          events_variable: event[:events]
      }

      case event[:name]
        when 'Transfer'
          ContractEventManagement::Transfer.new(process_event_param).perform
      end
    end


    def validate_event(event)
      valid_events = SMART_CONTRACT_EVENTS[event[:address]]

      return success if valid_events.present? && valid_events.includes?(event[:name])

      if valid_events.blank?
        notify_devs({transaction: transaction}.merge!(msg: "invalid event address"))
        return error_with_data(
            'c_rbe_1',
            'invalid event address',
            'invalid event address',
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

      return error_with_data(
          'c_rbe_1',
          'event is not needed',
          'event is not needed',
          GlobalConstant::ErrorAction.default,
          {}
      )
    end

    def notify_devs(error_data)
      ApplicationMailer.notify(
          body: {current_block_number: @current_block_number},
          data: {error_data: error_data},
          subject: 'Error while ReadBlockEvents'
      ).deliver
    end

  end

end
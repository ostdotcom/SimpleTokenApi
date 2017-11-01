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
      @current_block_number = @last_processed_block_number + 1

      @block_data_response = {}

      @current_block_hash, @block_execution_timestamp, @transactions = nil, nil, []
      @transaction_hash = nil
    end

    # Perform
    #
    # * Author:Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    def perform
      get_block_data
      r = process_response
      return r unless r.success?
      process_transactions


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

    def process_event(event)
      event[:events].each do |var_obj|
        case var_obj[:name]
          when '_account'
            @event_data[:address] = var_obj[:value]
          when '_phase'
            @event_data[:phase] = var_obj[:value]
        end
      end

    end

    def get_token
      data = {block_number: @current_block_number}
      payload = {data: data}
      JWT.encode(payload, GlobalConstant::PublicOpsApi.secret_key, 'HS256')
    end

    def get_block_data
      Rails.logger.info("read_block_events block number: #{@current_block_number} - Making API call ReadBlockEvents")
      @block_data_response = OpsApi::Request::GetBlockInfo.new.perform(get_token)
      Rails.logger.info("read_block_events --- block number: #{@current_block_number} --- block_fetched_response: #{@block_data.inspect}")
    end

    def process_response
      if @block_data_response.success?
        meta = @block_data_response.data[:meta]
        @transactions = @block_data_response.data[:transactions]

        if meta[:current_block][:block_number] != @current_block_number
          notify_devs(@block_data_response.merge { msg : "Urgent::Block returned is invalid" })
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


    def notify_devs(error_data)
      ApplicationMailer.notify(
          body: {@current_block_number : @current_block_number},
          data : {
          error_data: error_data
      },
          subject : 'Error while ReadBlockEvents'
      ).deliver
    end


  end

end
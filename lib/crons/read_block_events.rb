module Crons

  class ReadBlockEvents

    include Util::ResultHelper

    MIN_BLOCK_DIFFERENCE = 6

    # initialize
    #
    # * Author: Aman
    # * Date: 31/10/2017
    # * Reviewed By: Kedar
    #
    # @return [Crons::ReadBlockEvents]
    #
    def initialize(params)
      @last_processed_block_number = SaleGlobalVariable.last_block_processed.first.try(:variable_data).to_i
      @last_verified_block_number_for_total = SaleGlobalVariable.
        last_block_verified_for_tokens_sold_variable_kind.first.try(:variable_data).to_i
      @total_token_sold_count = nil
    end

    # Perform
    # How to handle execptions.What if one transaction cannot be processed
    #
    #
    # * Author: Aman
    # * Date: 31/10/2017
    # * Reviewed By: Kedar
    #
    def perform

      begin

        while true
          set_data_for_current_iteration

          get_block_transactions

          r = validate_response
          return r unless r.success?

          if blocks_trail_count >= MIN_BLOCK_DIFFERENCE

            process_transactions

            update_last_processed_block_number

            verify_token_count if blocks_trail_count == MIN_BLOCK_DIFFERENCE

          end

          return if blocks_trail_count <= MIN_BLOCK_DIFFERENCE

        end

      rescue StandardError => e
        return
      end

    end

    private

    # Set Data for current iteration
    #
    # * Author: Aman
    # * Date: 31/10/2017
    # * Reviewed By: Kedar
    #
    # Sets @current_block_number, @block_data_response, @highest_block_number,
    # @current_block_hash, @block_creation_timestamp, @transactions
    #
    def set_data_for_current_iteration
      @current_block_number = @last_processed_block_number + 1
      @block_data_response = {}
      @highest_block_number = nil
      @current_block_hash, @block_creation_timestamp = nil, nil
      @transactions = nil
    end

    # Get block from public node
    #
    # * Author: Aman
    # * Date: 31/10/2017
    # * Reviewed By: Kedar
    #
    # Sets [@block_data_response]
    #
    def get_block_transactions
      Rails.logger.info("read_block_events block number: #{@current_block_number} - Making API call ReadBlockEvents")
      @block_data_response = OpsApi::Request::GetBlockInfo.new.perform(public_api_request_params)
      Rails.logger.info("read_block_events --- block number: #{@current_block_number} --- block_fetched_response: #{@block_data_response.inspect}")
    end

    # Validates Block data
    #
    # * Author: Aman
    # * Date: 31/10/2017
    # * Reviewed By: Kedar
    #
    # @return [Result::Base]
    # Sets [@transactions, @current_block_hash, @block_creation_timestamp, @block_number, @highest_block_number]
    #
    def validate_response

      unless @block_data_response.success?
        notify_dev(@block_data_response.data.merge(msg: "Error while fetching block"))
        return error_with_data(
          'c_rbe_2',
          'error while fetching block',
          'error while fetching block',
          GlobalConstant::ErrorAction.default,
          {}
        )
      end

      meta = @block_data_response.data[:meta]
      @transactions = @block_data_response.data[:transactions]


      if (meta[:current_block][:block_number].to_i != @current_block_number)
        notify_dev(@block_data_response.data.merge(msg: "Urgent::Block returned is invalid"))
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
      @highest_block_number = meta[:hightest_block].to_i

      success
    end

    # No of blocks block processor is trailing by
    #
    # * Author: Aman
    # * Date: 31/10/2017
    # * Reviewed By:
    #
    # @return [Boolean]
    #
    def blocks_trail_count
      @highest_block_number - @current_block_number
    end

    # Process all transactions in a block
    #
    # * Author: Aman
    # * Date: 31/10/2017
    # * Reviewed By: Kedar
    #
    #
    def process_transactions
      @transactions.each do |transaction|
        transaction[:events_data].each do |event|

          r = validate_event(event)
          next unless r.success?

          contract_event_obj = create_contract_event(transaction[:transaction_hash], event)
          next if contract_event_obj.status != GlobalConstant::ContractEvent.recorded_status

          process_event(contract_event_obj)

        end

      end

    end

    # Gives the required params for public ops call
    #
    # * Author: Aman
    # * Date: 31/10/2017
    # * Reviewed By: Kedar
    #
    # Returns [Hash] data for get_block_transactions parameter
    #
    def public_api_request_params
      {
          block_number: @current_block_number
      }
    end

    # create user_contract_event
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    def create_contract_event(transaction_hash, event)
      event_kind = event[:name]
      contract_address = event[:address]

      contract_event_objs = ContractEvent.where(
          transaction_hash: transaction_hash,
          kind: event_kind,
          contract_address: contract_address
      ).all

      contract_event_status = GlobalConstant::ContractEvent.recorded_status

      if contract_event_objs.present?
        contract_event_objs.each do |contract_event_obj|
          return contract_event_obj if contract_event_obj.block_hash.downcase == @current_block_hash.downcase
        end

        contract_event_status = GlobalConstant::ContractEvent.duplicate_status
        notify_dev({transaction_hash: transaction_hash, event_kind: event_kind, event: event, msg: 'duplicate event'})
      end

      data = {event_data: event[:events]}.deep_symbolize_keys

      contract_event_obj = ContractEvent.create!({
                                                     block_hash: @current_block_hash,
                                                     transaction_hash: transaction_hash,
                                                     kind: event_kind,
                                                     contract_address: contract_address,
                                                     status: contract_event_status,
                                                     block_number: @current_block_number,
                                                     data: data
                                                 })
      contract_event_obj
    end


    # Validate event in a transaction
    #
    # * Author: Aman
    # * Date: 31/10/2017
    # * Reviewed By: Kedar
    #
    # @return [Result::Base] checks if event received is correct
    #
    def validate_event(event)

      return success if ContractEvent.kinds[event[:name]].present?

      notify_dev({transaction: transaction, event: event}.merge!(msg: "invalid event"))
      error_with_data(
          'c_rbe_3',
          'invalid event',
          'invalid event',
          GlobalConstant::ErrorAction.default,
          {}
      )
    end

    # Process an event in a transaction
    #
    # * Author: Aman
    # * Date: 31/10/2017
    # * Reviewed By: Kedar
    #
    def process_event(contract_event_obj)

      # skip processing for others
      return unless GlobalConstant::StFoundationContract.token_sale_contract_address ==
          contract_event_obj.contract_address

      case contract_event_obj.kind
        when GlobalConstant::ContractEvent.tokens_purchased_kind
          ContractEventManagement::Transfer.new(
              contract_event_obj: contract_event_obj, block_creation_timestamp: @block_creation_timestamp
          ).perform

          contract_event_obj.data[:event_data].each do |var_obj|
            if var_obj[:name] == '_totalSold'
              @total_token_sold_count = var_obj[:value].to_i
              break
            end
          end

        when GlobalConstant::ContractEvent.finalized_kind
          ContractEventManagement::Finalize.new(
              contract_event_obj: contract_event_obj
          ).perform

        else
          # nothing to do

      end

    end

    # Updates last procssed block number
    #
    # * Author: Aman
    # * Date: 31/10/2017
    # * Reviewed By: Kedar
    #
    # Sets [@last_processed_block_number]
    #
    def update_last_processed_block_number
      SaleGlobalVariable.last_block_processed.update_all(variable_data: @current_block_number.to_s)
      @last_processed_block_number = @current_block_number
    end

    # Verify if token sold count matches with our data after 60 blocks approx 15 mins
    #
    # * Author: Aman
    # * Date: 31/10/2017
    # * Reviewed By: Kedar
    #
    def verify_token_count
      return if (@last_verified_block_number_for_total + 60 > @current_block_number) ||
          @total_token_sold_count.nil?

      total_tokens_in_wei_sold_in_db = PurchaseLog.select('sum(st_wei_value) as total_tokens_in_wei_sold').
          first.total_tokens_in_wei_sold.to_i
      pre_sale_st_tokens_in_wei_sold = SaleGlobalVariable.pre_sale_data[:pre_sale_st_token_in_wei_value]

      ApplicationMailer.notify(
          body: {},
          data: {
              current_block_number: @current_block_number,
              total_tokens_sold_in_db: total_tokens_in_wei_sold_in_db,
              total_token_sold_count_in_event: @total_token_sold_count,
              pre_sale_st_tokens_in_wei_sold: pre_sale_st_tokens_in_wei_sold
          },
          subject: 'Data Mismatch For total tokens sold'
      ).deliver if @total_token_sold_count != (total_tokens_in_wei_sold_in_db + pre_sale_st_tokens_in_wei_sold)

      SaleGlobalVariable.last_block_verified_for_tokens_sold_variable_kind.update_all(variable_data: @current_block_number.to_s)
      @last_verified_block_number_for_total = @current_block_number
    end

    # Notify devs in case of an error condition
    #
    # * Author: Aman
    # * Date: 31/10/2017
    # * Reviewed By: Kedar
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
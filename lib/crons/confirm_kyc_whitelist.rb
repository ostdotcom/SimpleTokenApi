module Crons

  class ConfirmKycWhitelist

    include Util::ResultHelper

    # initialize
    #
    # * Author: Kedar, Abhay
    # * Date: 26/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Crons::ConfirmKycWhitelist]
    #
    def initialize(params)
    end

    # Perform
    #
    # * Author: Kedar, Abhay
    # * Date: 26/10/2017
    # * Reviewed By: Sunil
    #
    def perform

      KycWhitelistLog.
          kyc_whitelist_non_confirmed.
          where("next_timestamp <= ?", Time.now.to_i).
          where(failed_reason: GlobalConstant::KycWhitelistLog.not_failed).
          where(status: GlobalConstant::KycWhitelistLog.kyc_whitelist_confirmation_pending_statuses).
          find_in_batches(batch_size: 100).each do |batched_records|

        batched_records.each do |kyc_whitelist_log|
          initialize_for_iteration(kyc_whitelist_log)
          begin
            r = get_tx_info
            next unless r.success?

            if is_unexpected_status_value?
              notify_devs({kyc_whitelist_log: kyc_whitelist_log, tx_info_status: @tx_info_status},
                          "INVALID TRANSACTION STATUS FROM PUBLIC OPS")
              next
            end

            if invalid_or_failed_txn_status?
              process_failed_txn_status
              notify_devs({kyc_whitelist_log: kyc_whitelist_log, tx_info_status: @tx_info_status},
                          "Whitelist Transaction status has failed with status-#{@transaction_status}")
              next
            end

            if pending_txn_status?
              increment_next_timestamp
              next
            end

            if pending_whitelist_log_status? || !contract_event_processed?

              r = process_pending_status_record
              next unless r.success?

            elsif done_whitelist_log_status?

              r = process_done_status_record
              next unless r.success?

            else
              fail("user_kyc_whitelist_log - #{@kyc_whitelist_log.id} - Unreachable Code")
            end

          rescue StandardError => e
            return exception_with_data(
                e,
                'c_ckw_p_1',
                'exception in confirm kyc whitelist: ' + e.message,
                'Something went wrong.',
                GlobalConstant::ErrorAction.default,
                {kyc_whitelist_log_id: kyc_whitelist_log.id}
            )
          end

        end

      end

    end

    private

    # Initialize for iteration
    #
    # * Author: Kedar, Alpesh
    # * Date: 26/10/2017
    # * Reviewed By: Sunil
    #
    def initialize_for_iteration(kyc_whitelist_log)
      @kyc_whitelist_log = kyc_whitelist_log
      @tx_info_status, @block_hash, @block_number, @transaction_hash, @events_data, @transaction_status = nil, nil, nil, nil, nil, nil
      @user_id = nil
    end

    # Check block mine status
    #
    # * Author: Kedar, Alpesh
    # * Date: 26/10/2017
    # * Reviewed By: Sunil
    #
    # Sets @tx_info_status, @block_hash, @block_number, @transaction_hash, @events_data
    #
    # @return [Result::Base]
    #
    def get_tx_info
      # check if the transaction is mined in a block
      @transaction_hash = @kyc_whitelist_log.transaction_hash

      Rails.logger.info("user_kyc_whitelist_log - #{@kyc_whitelist_log.id} - Making API call GetWhitelistConfirmation")
      @tx_info_status = OpsApi::Request::GetWhitelistConfirmation.new.perform({transaction_hash: @transaction_hash})

      Rails.logger.info("user_kyc_whitelist_log - #{@kyc_whitelist_log.id} - transaction_mined_response: #{@tx_info_status.inspect}")

      if @tx_info_status.success?
        @block_hash = @tx_info_status.data[:block_hash]
        @block_number = @tx_info_status.data[:block_number].to_i
        @events_data = @tx_info_status.data[:events_data]
        @transaction_status = @tx_info_status.data[:status].to_s.downcase
        success
      else
        message = "Error in get transaction Status, PublicOps Or Geth may be down"
        notify_devs({transaction_hash: @transaction_hash, tx_info_status: @tx_info_status}, message)

        error_with_data(
            'l_c_ckw_gti_1',
            message,
            message,
            GlobalConstant::ErrorAction.default,
            {}
        )
      end
    end

    # Get contract address
    #
    # * Author: Aman
    # * Date: 29/12/2017
    # * Reviewed By:
    #
    # @return [Integer] contract address
    #
    def get_contract_address
      client_whitelist_objs[@kyc_whitelist_log.client_id].contract_address
    end

    # Get contract address
    #
    # * Author: Aman
    # * Date: 29/12/2017
    # * Reviewed By:
    #
    # @return [Integer] contract address
    #
    def client_whitelist_objs
      @client_whitelist_objs ||= ClientWhitelistDetail.where(status: GlobalConstant::ClientWhitelistDetail.active_status).all.index_by(&:client_id)
    end

    # is done status
    #
    # * Author: Kedar, Alpesh
    # * Date: 26/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Boolean]
    #
    def done_whitelist_log_status?
      @kyc_whitelist_log.status == GlobalConstant::KycWhitelistLog.done_status
    end

    # is pending status
    #
    # * Author: Kedar, Alpesh
    # * Date: 26/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Boolean]
    #
    def pending_whitelist_log_status?
      @kyc_whitelist_log.status == GlobalConstant::KycWhitelistLog.pending_status
    end

    # Is pending transaction
    #
    # * Author: Sachin
    # * Date: 31/5/2018
    # * Reviewed By:
    def pending_txn_status?
      GlobalConstant::KycWhitelistLog.pending_txn_status == @transaction_status
    end

    # Is invalid transaction
    #
    # * Author: Sachin
    # * Date: 31/5/2018
    # * Reviewed By:
    def invalid_or_failed_txn_status?
      [GlobalConstant::KycWhitelistLog.invalid_txn_status, GlobalConstant::KycWhitelistLog.failed_txn_status].include?(@transaction_status)
    end

    def invalid_txn_status?
      [GlobalConstant::KycWhitelistLog.invalid_txn_status].include?(@transaction_status)
    end

    # Is invalid transaction
    #
    # * Author: Sachin
    # * Date: 31/5/2018
    # * Reviewed By:
    def is_unexpected_status_value?
      GlobalConstant::KycWhitelistLog.all_txn_statuses.exclude?(@transaction_status)
    end

    # To increment next_timestamp
    #
    # * Author: Sachin
    # * Date: 31/5/2018
    # * Reviewed By:
    def increment_next_timestamp
      current_timestamp = Time.now.to_i
      time_since_row_entry = current_timestamp - @kyc_whitelist_log.created_at.to_i
      time_increment = (time_since_row_entry * GlobalConstant::KycWhitelistLog.next_timestamp_increment_factor).to_i

      if time_since_row_entry > GlobalConstant::KycWhitelistLog.extreme_wait_interval
        notify_devs(
            {kyc_whitelist_log: @kyc_whitelist_log, tx_info_status: @tx_info_status},
            "IMMEDIATE ATTENTION NEEDED. Transaction is pending for too long. Time Interval- #{(time_since_row_entry / 60)} minutes"
        )
      end

      @kyc_whitelist_log.next_timestamp = current_timestamp + time_increment
      @kyc_whitelist_log.save!
    end

    # Process pending status record
    #
    # * Author: Kedar, Alpesh
    # * Date: 26/10/2017
    # * Reviewed By: Sunil
    #
    def process_pending_status_record
      Rails.logger.info("user_kyc_whitelist_log - #{@kyc_whitelist_log.id} - If Pending Status")

      # this means it is confirmed
      r = record_event

      if r.success?
        # todo: wait for next iteration before confirming
        notify_devs(
            {kyc_whitelist_log_id: @kyc_whitelist_log.id, client_id: @kyc_whitelist_log.client_id},
            "Event not received but marked successfull by confirm cron"
        )
      else
        Rails.logger.info("user_kyc_whitelist_log - #{@kyc_whitelist_log.id} - error of record event ::" + r.error_display_text)

        @kyc_whitelist_log.reload
        process_failed_txn_status

        return error_with_data(
            'l_c_ckw_2',
            r.error_display_text,
            r.error_display_text,
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

      success
    end

    # Process done status record
    #
    # * Author: Kedar, Alpesh
    # * Date: 26/10/2017
    # * Reviewed By: Sunil
    #
    def process_done_status_record
      Rails.logger.info("user_kyc_whitelist_log - #{@kyc_whitelist_log.id} - If Done Status")
      mark_whitelisting_confirmed
      success
    end

    # Process done status record
    #
    # * Author: Sachin
    # * Date: 01/06/2018
    # * Reviewed By: Aman
    #
    def contract_event_processed?
      ContractEvent.where(
          transaction_hash: @transaction_hash,
          kind: GlobalConstant::ContractEvent.whitelist_updated_kind,
          block_hash: @block_hash
      ).present?
    end

    # Process failed transaction status record
    #
    # * Author: Sachin
    # * Date: 01/06/2018
    # * Reviewed By: Sunil
    #
    def process_failed_txn_status

      Rails.logger.info("user_kyc_whitelist_log - #{@kyc_whitelist_log.id} - has failed Status")

      if invalid_txn_status?
        @kyc_whitelist_log.mark_failed_with_reason(GlobalConstant::KycWhitelistLog.invalid_transaction_failed)
      else
        @kyc_whitelist_log.mark_failed_with_reason(GlobalConstant::KycWhitelistLog.invalid_event_failed)
      end

      r = fetch_user_kyc_detail
      return r unless r.success?

      user_kyc_detail = r.data[:user_kyc_detail]

      if @kyc_whitelist_log.phase == 0
        AdminManagement::ProcessUnwhitelist.new({kyc_whitelist_log: @kyc_whitelist_log,
                                                 user_kyc_detail: user_kyc_detail}).perform
      else
        user_kyc_detail.whitelist_status = GlobalConstant::KycWhitelistLog.failed_status
        user_kyc_detail.save! if user_kyc_detail.changed?
      end

      success
    end


    # record event
    #
    # * Author: Kedar, Abhay
    # * Date: 26/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def record_event
      Rails.logger.info("user_kyc_whitelist_log - #{@kyc_whitelist_log.id} - All success! Let's record event.")
      data = {
          transaction_hash: @transaction_hash,
          block_hash: @block_hash,
          block_number: @block_number,
          events_data: @events_data
      }.deep_symbolize_keys

      WhitelistManagement::ProcessAndRecordEvent.new(decoded_token_data: data).perform
    end

    # Fetch user kyc detail
    #
    # * Author: Kedar, Alpesh
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    # @params [Array] prospective_user_extended_detail_ids
    #
    # Sets @user_id
    #
    # @return [Result::Base]
    #
    def fetch_user_kyc_detail
      user_kyc_details = Md5UserExtendedDetail.get_user_kyc_details(@kyc_whitelist_log.client_id, @kyc_whitelist_log.ethereum_address)

      if user_kyc_details.blank?
        @kyc_whitelist_log.mark_failed_with_reason(GlobalConstant::KycWhitelistLog.invalid_kyc_failed)
        notify_devs(
            {kyc_whitelist_log_id: @kyc_whitelist_log.id, ethereum_address: @kyc_whitelist_log.ethereum_address},
            "IMMEDIATE ATTENTION NEEDED. no approved user_kyc_detail records found for address"
        )

        return error_with_data(
            'l_c_ckw_5',
            'no approved user_kyc_detail records found for address.',
            'no approved user_kyc_detail records found for address',
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

      if user_kyc_details.count > 1
        @kyc_whitelist_log.mark_failed_with_reason(GlobalConstant::KycWhitelistLog.invalid_kyc_failed)
        notify_devs(
            {kyc_whitelist_log_id: @kyc_whitelist_log.id, ethereum_address: @kyc_whitelist_log.ethereum_address},
            "IMMEDIATE ATTENTION NEEDED. multiple approved user_kyc_detail records found for same address"
        )

        return error_with_data(
            'l_c_ckw_6',
            'multiple approved user_kyc_detail records found for same address.',
            'multiple approved user_kyc_detail records found for same address',
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

      user_kyc_detail = user_kyc_details.first

      if [GlobalConstant::UserKycDetail.started_whitelist_status, GlobalConstant::UserKycDetail.done_whitelist_status].exclude?(user_kyc_detail.whitelist_status)
        @kyc_whitelist_log.mark_failed_with_reason(GlobalConstant::KycWhitelistLog.invalid_kyc_failed)
        notify_devs(
            {kyc_whitelist_log_id: @kyc_whitelist_log.id, ethereum_address: @kyc_whitelist_log.ethereum_address},
            "IMMEDIATE ATTENTION NEEDED. invalid whitelist status-#{user_kyc_detail.whitelist_status} of user kyc detail"
        )

        return error_with_data(
            'l_c_ckw_7',
            'invalid whitelist status',
            'invalid whitelist status',
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

      @user_id = user_kyc_detail.user_id

      success_with_data(user_kyc_detail: user_kyc_detail)
    end

    # notify devs if required
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    def notify_devs(error_data, err_message)
      ApplicationMailer.notify(
          body: {err_message: err_message},
          data: {
              error_data: error_data
          },
          subject: 'Error while ConfirmKycWhitelist'
      ).deliver
    end

    # Method to mark Kyc whitelist log as confirmed
    #
    # # * Author: Pankaj
    # * Date: 17/05/2018
    # * Reviewed By:
    #
    def mark_whitelisting_confirmed
      @kyc_whitelist_log.mark_confirmed

      r = fetch_user_kyc_detail
      return r unless r.success?

      user_kyc_detail = r.data[:user_kyc_detail]

      if @kyc_whitelist_log.phase == 0
        AdminManagement::ProcessUnwhitelist.new({kyc_whitelist_log: @kyc_whitelist_log,
                                                 user_kyc_detail: user_kyc_detail}).perform
      else
        user_kyc_detail.kyc_confirmed_at = Time.now.to_i
        user_kyc_detail.save!
      end

    end

  end

end
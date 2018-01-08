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
      @kyc_whitelist_log = nil
      @tx_info_status, @block_hash, @block_number, @transaction_hash, @events_data =  nil, nil, nil, nil, nil
      @user_id = nil
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
          where("created_at < '#{(Time.now - 5.minutes).to_s(:db)}'").
          where(is_attention_needed: GlobalConstant::KycWhitelistLog.attention_not_needed).
          find_in_batches(batch_size: 100).each do |batched_records|

        batched_records.each do |kyc_whitelist_log|

          initialize_for_iteration(kyc_whitelist_log)

          r = get_tx_info
          next unless r.success?

          r = query_contract
          unless r.success?
            notify_devs(
              {ethereum_address: @kyc_whitelist_log.ethereum_address},
              "IMMEDIATE ATTENTION NEEDED. Does not exist in contract OR phase mis match."
            )
            next
          end

          if pending_status?

            r = process_pending_status_record
            next unless r.success?

          elsif done_status?

            r = process_done_status_record
            next unless r.success?

          else
            fail("user_kyc_whitelist_log - #{@kyc_whitelist_log.id} - Unreachable Code")
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
      @tx_info_status, @block_hash, @block_number, @transaction_hash, @events_data =  nil, nil, nil, nil, nil
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
      Rails.logger.info("user_kyc_whitelist_log - #{@kyc_whitelist_log.id} - Making API call GetWhitelistConfirmation")
      @tx_info_status = OpsApi::Request::GetWhitelistConfirmation.new.perform(
        {transaction_hash: @kyc_whitelist_log.transaction_hash}
      )

      Rails.logger.info(
        "user_kyc_whitelist_log - #{@kyc_whitelist_log.id} - transaction_mined_response: #{@tx_info_status.inspect}"
      )

      if @tx_info_status.success?
        @block_hash = @tx_info_status.data[:block_hash]
        @transaction_hash = @tx_info_status.data[:transaction_hash]
        @block_number = @tx_info_status.data[:block_number].to_i
        @events_data = @tx_info_status.data[:events_data]
        success
      else

        handle_error('Block Not Mined')

        error_with_data(
          'l_c_ckw_1',
          'block not mined',
          'block not mined',
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
    def done_status?
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
    def pending_status?
      @kyc_whitelist_log.status == GlobalConstant::KycWhitelistLog.pending_status
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
        @kyc_whitelist_log.mark_confirmed
      else
        return error_with_data(
          'l_c_ckw_2',
          'block not mined',
          'block not mined',
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

      # Block Hash Mismatch
      contract_event = ContractEvent.where(
          transaction_hash: @transaction_hash,
          kind: GlobalConstant::ContractEvent.whitelist_updated_kind,
          contract_address: get_contract_address,
          block_hash: @block_hash
      ).first

      if contract_event.present? && (contract_event.block_hash == @block_hash)
        @kyc_whitelist_log.mark_confirmed
      else
        handle_error('Block Value Mismatch')

        return error_with_data(
          'l_c_ckw_3',
          'block hash mismatch',
          'block hash mismatch',
          GlobalConstant::ErrorAction.default,
          {}
        )
      end

      success
    end

    # query contract
    #
    # * Author: Kedar
    # * Date: 13/11/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def query_contract
      r = OpsApi::Request::GetWhitelistStatus.new.perform(contract_address: get_contract_address, ethereum_address: @kyc_whitelist_log.ethereum_address)
      return r unless r.success?

      if r.data['phase'].to_i == @kyc_whitelist_log.phase
        success
      else
        error_with_data(
          'l_c_ckw_3.1',
          'phase mismatch',
          'phase mismatch',
          GlobalConstant::ErrorAction.default,
          {}
        )
      end
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

    # Get ethereum address
    #
    # * Author: Kedar, Abhay
    # * Date: 26/10/2017
    # * Reviewed By: Sunil
    #
    # @param [UserKycDetal]
    #
    def get_ethereum_address(user_kyc_detail)
      user_extended_detail = UserExtendedDetail.where(id: user_kyc_detail.user_extended_detail_id).first
      kyc_salt_e = user_extended_detail.kyc_salt
      r = Aws::Kms.new('kyc', 'admin').decrypt(kyc_salt_e)
      kyc_salt_d = r.data[:plaintext]
      local_cipher_obj = LocalCipher.new(kyc_salt_d)
      local_cipher_obj.decrypt(user_extended_detail.ethereum_address).data[:plaintext]
    end

    # Handle error
    #
    # * Author: Kedar, Abhay
    # * Date: 26/10/2017
    # * Reviewed By: Sunil
    #
    def handle_error(error_type)
      Rails.logger.info("user_kyc_whitelist_log - #{@kyc_whitelist_log.id} - #{error_type}")

      error_data = {transaction_mined_response: @tx_info_status.to_json}
      Rails.logger.info("user_kyc_whitelist_log - #{@kyc_whitelist_log.id} - Changing to is attention needed")

      # change flag to attention required
      @kyc_whitelist_log.is_attention_needed = GlobalConstant::KycWhitelistLog.attention_needed
      @kyc_whitelist_log.save!

      r = get_prospective_user_extended_detail_ids
      return unless r.success?

      r = fetch_user_kyc_detail(r.data[:prospective_user_extended_detail_ids])
      return unless r.success?

      UserActivityLogJob.new().perform({
                                           user_id: @user_id,
                                           action: GlobalConstant::UserActivityLog.kyc_whitelist_attention_needed,
                                           action_timestamp: Time.now.to_i,
                                           extra_data: {
                                               error_type: error_type,
                                               user_kyc_whitelist_log_id: @kyc_whitelist_log.id,
                                               error_data: error_data
                                           }
                                       })

    end

    # Get prospective user extended detail ids
    #
    # * Author: Kedar, Alpesh
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def get_prospective_user_extended_detail_ids
      prospective_user_extended_detail_ids = Md5UserExtendedDetail.where(
        ethereum_address: Md5UserExtendedDetail.get_hashed_value(@kyc_whitelist_log.ethereum_address)
      ).pluck(:user_extended_detail_id)

      if prospective_user_extended_detail_ids.blank?
        notify_devs(
          {ethereum_address: @kyc_whitelist_log.ethereum_address},
          "IMMEDIATE ATTENTION NEEDED. eth address not associated with any user, still trying to confirm kyc whitelisting."
        )

        return error_with_data(
          'l_c_ckw_4',
          'eth address not associated with any user, still trying to confirm kyc whitelisting.',
          'eth address not associated with any user, still trying to confirm kyc whitelisting.',
          GlobalConstant::ErrorAction.default,
          {}
        )
      end
      success_with_data(prospective_user_extended_detail_ids: prospective_user_extended_detail_ids)
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
    def fetch_user_kyc_detail(prospective_user_extended_detail_ids)
      user_kyc_details = UserKycDetail.kyc_admin_and_cynopsis_approved.where(client_id: @kyc_whitelist_log.client_id,
        user_extended_detail_id: prospective_user_extended_detail_ids
      ).all

      if user_kyc_details.blank?
        notify_devs(
          {transaction_hash: @transaction_hash},
          "IMMEDIATE ATTENTION NEEDED. no approved user_kyc_detail records found for same address"
        )

        return error_with_data(
          'l_c_ckw_5',
          'no approved user_kyc_detail records found for same address.',
          'no approved user_kyc_detail records found for same address',
          GlobalConstant::ErrorAction.default,
          {}
        )
      end

      if user_kyc_details.count > 1
        notify_devs(
          {transaction_hash: @transaction_hash},
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

      if user_kyc_detail.whitelist_status != GlobalConstant::UserKycDetail.started_whitelist_status
        notify_devs(
          {transaction_hash: @transaction_hash},
          "IMMEDIATE ATTENTION NEEDED. invalid whitelist status"
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

      success

    end

    # notify devs if required
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    def notify_devs(error_data, user_id)
      ApplicationMailer.notify(
          body: {user_id: user_id},
          data: {
              error_data: error_data
          },
          subject: 'Error while ConfirmKycWhitelist'
      ).deliver
    end

  end

end
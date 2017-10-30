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
      @block_mine_status, @block_hash, @transaction_hash, @event_data =  nil, nil, nil, {}
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

          r = check_block_mine_status
          next unless r.success?

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
      @block_mine_status, @block_hash, @transaction_hash, @event_data =  nil, nil, nil, {}
      @user_id = nil
    end

    # Check block mine status
    #
    # * Author: Kedar, Alpesh
    # * Date: 26/10/2017
    # * Reviewed By: Sunil
    #
    # Sets @block_mine_status, @block_hash, @transaction_hash, @event_data
    #
    # @return [Result::Base]
    #
    def check_block_mine_status
      data = {transaction_hash: @kyc_whitelist_log.transaction_hash}
      payload = {data: data}
      token = JWT.encode(payload, GlobalConstant::PublicOpsApi.secret_key, 'HS256')

      # check if the transaction is mined in a block
      Rails.logger.info("user_kyc_whitelist_log - #{@kyc_whitelist_log.id} - Making API call GetWhitelistConfirmation")
      @block_mine_status = OpsApi::Request::GetWhitelistConfirmation.new.perform(token)

      Rails.logger.info("user_kyc_whitelist_log - #{@kyc_whitelist_log.id} - transaction_mined_response: #{@block_mine_status.inspect}")

      if @block_mine_status.success?
        @block_hash = @block_mine_status.data[:block_hash]
        @transaction_hash = @block_mine_status.data[:transaction_hash]
        @transaction_event = @block_mine_status.data[:events_data].first
        @transaction_event[:events].each do |var_obj|
          case var_obj[:name]
            when '_account'
              @event_data[:address] = var_obj[:value]
            when '_phase'
              @event_data[:phase] = var_obj[:value]
          end
        end

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
        transaction_hash: @transaction_hash
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
          event_data: @event_data
      }

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

      error_data = {transaction_mined_response: @block_mine_status.to_json}
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
      user_kyc_details = UserKycDetail.kyc_admin_and_cynopsis_approved.where(
        user_extended_detail_id: prospective_user_extended_detail_ids
      ).all

      if user_kyc_details.blank?
        notify_devs(
          {ethereum_address: @ethereum_address, phase: @phase, transaction_hash: @transaction_hash},
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
          {ethereum_address: @ethereum_address, phase: @phase, transaction_hash: @transaction_hash},
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
          {ethereum_address: @ethereum_address, phase: @phase, transaction_hash: @transaction_hash},
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

      if UserKycDetail.token_sale_participation_phases[user_kyc_detail.token_sale_participation_phase] != @phase
        notify_devs(
          {ethereum_address: @ethereum_address, phase: @phase, transaction_hash: @transaction_hash},
          "IMMEDIATE ATTENTION NEEDED. phase mismatch"
        )

        return error_with_data(
          'l_c_ckw_8',
          'phase mismatch',
          'phase mismatch',
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
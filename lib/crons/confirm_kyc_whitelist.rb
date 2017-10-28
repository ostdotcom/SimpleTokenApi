module Crons

  class ConfirmKycWhitelist

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
      UserKycWhitelistLog
          .kyc_whitelist_non_confirmed
          .where("created_at < '#{(Time.now - 5.minutes).to_s(:db)}'")
          .where(is_attention_needed: GlobalConstant::UserKycWhitelistLog.attention_not_needed)
          .find_in_batches(batch_size: 100).each do |batched_records|

        batched_records.each do |user_kyc_whitelist_log|
          token = get_token({transaction_hash: user_kyc_whitelist_log.transaction_hash})
          # check if the transaction is mined in a block
          Rails.logger.info("user_kyc_whitelist_log - #{user_kyc_whitelist_log.id} - Making API call GetWhitelistConfirmation")
          transaction_mined_response = OpsApi::Request::GetWhitelistConfirmation.new.perform(token)
          Rails.logger.info("user_kyc_whitelist_log - #{user_kyc_whitelist_log.id} - transaction_mined_response: #{transaction_mined_response}")

          if user_kyc_whitelist_log.status == GlobalConstant::UserKycWhitelistLog.pending_status

            Rails.logger.info("user_kyc_whitelist_log - #{user_kyc_whitelist_log.id} - If Pending Status")

            unless transaction_mined_response.success?
              Rails.logger.info("user_kyc_whitelist_log - #{user_kyc_whitelist_log.id} - Block Not Mined")
              handle_error(user_kyc_whitelist_log, 'Block Not Mined', {transaction_mined_response: transaction_mined_response.to_json})
              next
            end

            # this means it is confirmed
            block_hash = transaction_mined_response.data['transaction_info']['block_hash']
            Rails.logger.info("user_kyc_whitelist_log - #{user_kyc_whitelist_log.id} - All success! Let's record event.")
            r = record_event(user_kyc_whitelist_log, block_hash)
            if r.success?
              user_kyc_whitelist_log.mark_confirmed
            else
              next
            end

          elsif user_kyc_whitelist_log.status == GlobalConstant::UserKycWhitelistLog.done_status

            Rails.logger.info("user_kyc_whitelist_log - #{user_kyc_whitelist_log.id} - If Done Status")

            if transaction_mined_response.success?
              # Block Hash Mismatch
              block_hash = transaction_mined_response.data['transaction_info']['block_hash']
              user_contract_event = UserContractEvent.where(transaction_hash: user_kyc_whitelist_log.transaction_hash).first

              if user_contract_event.present? && (user_contract_event.block_hash == block_hash)
                user_kyc_whitelist_log.mark_confirmed
              else
                handle_error(user_kyc_whitelist_log, 'Block Value Mismatch', {transaction_mined_response: transaction_mined_response.to_json})
              end

            else
              Rails.logger.info("user_kyc_whitelist_log - #{user_kyc_whitelist_log.id} - Block Not Mined")
              handle_error(user_kyc_whitelist_log, 'Block Not Mined', {transaction_mined_response: transaction_mined_response.to_json})
              next
            end

          else
            fail("user_kyc_whitelist_log - #{user_kyc_whitelist_log.id} - Unreachable Code")
          end

        end

      end

    end

    private

    # Create encrypted Token for parameters
    #
    # * Author: Kedar, Abhay
    # * Date: 26/10/2017
    # * Reviewed By: Sunil
    #
    def get_token(data)
      payload = {data: data}
      JWT.encode(payload, GlobalConstant::PublicOpsApi.secret_key, 'HS256')
    end

    # record event
    #
    # * Author: Kedar, Abhay
    # * Date: 26/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def record_event(user_kyc_whitelist_log, block_hash)

      user_kyc_detail = UserKycDetail.where(user_id: user_kyc_whitelist_log.user_id).first

      data = {
          transaction_hash: user_kyc_whitelist_log.transaction_hash,
          block_hash: block_hash,
          event_data: {
              address: get_ethereum_address(user_kyc_detail),
              phase: UserKycDetail.token_sale_participation_phases[user_kyc_detail.token_sale_participation_phase]
          }
      }

      WhitelistManagement::RecordEvent.new(decoded_token_data: data).perform
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
    def handle_error(user_kyc_whitelist_log, error_type, error_data)
      Rails.logger.info("user_kyc_whitelist_log - #{user_kyc_whitelist_log.id} - Changing to is attention needed")
      # change flag to attention required
      @user_kyc_whitelist_log.is_attention_needed = GlobalConstant::UserKycWhitelistLog.attention_needed
      user_kyc_whitelist_log.save!
      UserActivityLogJob.new().perform({
                                           user_id: user_kyc_whitelist_log.user_id,
                                           action: GlobalConstant::UserActivityLog.kyc_whitelist_attention_needed,
                                           action_timestamp: Time.now.to_i,
                                           extra_data: {
                                               error_type: error_type,
                                               user_kyc_whitelist_log_id: user_kyc_whitelist_log.id,
                                               error_data: error_data
                                           }
                                       })
    end

  end

end
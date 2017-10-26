module Crons

  class ConfirmKycWhitelist

    require 'jwt'

    # initialize
    #
    # * Author: Kedar, Abhay
    # * Date: 26/10/2017
    # * Reviewed By:
    #
    # @return [Crons::ConfirmKycWhitelist]
    #
    def initialize
    end

    # Perform
    #
    # * Author: Kedar, Abhay
    # * Date: 26/10/2017
    # * Reviewed By:
    #
    def perform
      UserKycWhitelistLog
        .kyc_whitelist_non_confirmed
        .where("created_at < #{(Time.now - 5.minutes).to_s(:db)}")
        .find_in_batches(batch_size: 100).each do |batched_records|

          batched_records.each do |user_kyc_whitelist_log|
            token = get_token({transaction_hash: user_kyc_whitelist_log.transaction_hash})
            # check if the transaction is mined in a block
            transaction_mined_response = PrivateOpsApi::Request::GetWhitelistConfirmation.new.perform(token)

            if user_kyc_whitelist_log.status == GlobalConstant::UserKycWhitelistLog.pending_status

              if not_mined?(transaction_mined_response)
                handle_error(user_kyc_whitelist_log)
                next
              end

              # this means it is confirmed
              block_hash = transaction_mined_response.data[:response]['block_hash']
              r = record_event(user_kyc_whitelist_log, block_hash)
              if r.success?
                mark_confirmed(user_kyc_whitelist_log)
              else
                next
              end

            elsif user_kyc_whitelist_log.status == GlobalConstant::UserKycWhitelistLog.done_status

              if not_mined?(transaction_mined_response)
                next
              end

              mark_confirmed(user_kyc_whitelist_log)
            end

          end

      end

    end

    private

    # Create encrypted Token for parameters
    #
    # * Author: Kedar, Abhay
    # * Date: 26/10/2017
    # * Reviewed By:
    #
    def get_token(data)
      payload = {data: data}
      JWT.encode(payload, GlobalConstant::PublicOpsApi.secret_key, 'HS256')
    end

    # is not mined
    #
    # * Author: Kedar, Abhay
    # * Date: 26/10/2017
    # * Reviewed By:
    #
    # @return [Boolean]
    #
    def not_mined?(transaction_mined_response)
      !transaction_mined_response.success? || !transaction_mined_response.data[:response]["success"]
    end

    # record event
    #
    # * Author: Kedar, Abhay
    # * Date: 26/10/2017
    # * Reviewed By:
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

      token = get_token(data)

     WhitelistManagement::RecordEvent.new(token: token).perform
    end

    # Get etereum address
    #
    # * Author: Kedar, Abhay
    # * Date: 26/10/2017
    # * Reviewed By:
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
    # * Reviewed By:
    #
    def handle_error(user_kyc_whitelist_log)
      user_kyc_whitelist_log.is_attention_needed = GlobalConstant::UserKycWhitelistLog.attention_needed
      user_kyc_whitelist_log.save!
      # change flag to attention required
    end

    # Mark confirmed
    #
    # * Author: Kedar, Abhay
    # * Date: 26/10/2017
    # * Reviewed By:
    #
    def mark_confirmed(user_kyc_whitelist_log)
      user_kyc_whitelist_log.status = GlobalConstant::UserKycWhitelistLog.confirmed_status
      user_kyc_whitelist_log.save!
      # change flag to attention required
    end

  end

end
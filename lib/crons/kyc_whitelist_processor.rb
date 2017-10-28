module Crons

  class KycWhitelistProcessor

    # initialize
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Crons::KycWhitelistProcessor]
    #
    def initialize(params)
    end

    # public method to process hooks
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    def perform
      UserKycDetail.kyc_admin_and_cynopsis_approved.whitelist_status_unprocessed.find_in_batches(batch_size: 10) do |u_k_detail_objs|
        u_k_detail_objs.each do |user_kyc_detail|
          begin
            token = get_token(user_kyc_detail)
            Rails.logger.info("user_kyc_detail - #{user_kyc_detail.id} - Starting PrivateOps API Call ")
            r = OpsApi::Request::Whitelist.new.whitelist(token)

            unless r.success?
              handle_error(user_kyc_detail, 'PrivateOpsApi Error', {private_ops_api_response: r})
              next
            end

            transaction_hash = r.data["transaction_hash"]

            Rails.logger.info("user_kyc_detail - #{user_kyc_detail.id} - Create entry in UserKycWhitelistLog")
            UserKycWhitelistLog.create!({
                                            user_id: user_kyc_detail.user_id,
                                            transaction_hash: transaction_hash,
                                            status: GlobalConstant::UserKycWhitelistLog.pending_status
                                        })

            user_kyc_detail.whitelist_status = GlobalConstant::UserKycDetail.started_whitelist_status
            user_kyc_detail.save!
          rescue => e
            Rails.logger.info("Exception: #{e.inspect}")
            handle_error(user_kyc_detail, "Exception - #{e.inspect}", {exception: e})
          end

        end
      end
    end

    private

    # Handle errors
    #
    # * Author: Abhay
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    def handle_error(user_kyc_detail, error_type, error_data)
      notify_devs(error_data, user_kyc_detail.user_id)
      Rails.logger.info("user_kyc_detail - #{user_kyc_detail.id} - Changing user_kyc_detail whitelist_status to failed")
      user_kyc_detail.whitelist_status = GlobalConstant::UserKycDetail.failed_whitelist_status
      user_kyc_detail.save!

      UserActivityLogJob.new().perform({
                                           user_id: user_kyc_detail.user_id,
                                           action: GlobalConstant::UserActivityLog.kyc_whitelist_processor_error,
                                           action_timestamp: Time.now.to_i,
                                           extra_data: {
                                               user_kyc_detail_id: user_kyc_detail.id,
                                               error_type: error_type,
                                               error_data: error_data
                                           }
                                       })
    end

    # Create encrypted Token for whitelisting parameter
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    def get_token(user_kyc_detail)
      data = {
          address: get_ethereum_address(user_kyc_detail),
          phase: UserKycDetail.token_sale_participation_phases[user_kyc_detail.token_sale_participation_phase]
      }

      payload = {data: data}
      JWT.encode(payload, GlobalConstant::PrivateOpsApi.secret_key, 'HS256')
    end

    # Get Decrypted ethereum address of user
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    def get_ethereum_address(user_kyc_detail)
      user_extended_detail = UserExtendedDetail.where(id: user_kyc_detail.user_extended_detail_id).first
      kyc_salt_e = user_extended_detail.kyc_salt
      r = Aws::Kms.new('kyc', 'admin').decrypt(kyc_salt_e)
      kyc_salt_d = r.data[:plaintext]
      local_cipher_obj = LocalCipher.new(kyc_salt_d)
      local_cipher_obj.decrypt(user_extended_detail.ethereum_address).data[:plaintext]
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
          subject: 'Error while KycWhitelistProcessor'
      ).deliver
    end

  end

end
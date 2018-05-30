module Crons

  class KycWhitelistProcessor

    include Util::ResultHelper

    EXPECTED_CONFIRM_WAIT_INTERVAL = 3.minutes.to_i

    # initialize
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Crons::KycWhitelistProcessor]
    #
    def initialize(params)
      @api_data = {}
      @user_kyc_detail = nil
      @transaction_hash = nil
      @nonce = nil
      @gas_price = nil
    end

    # public method to process hooks
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    def perform
      @client_whitelist_objs = ClientWhitelistDetail.where(status: GlobalConstant::ClientWhitelistDetail.active_status).all.index_by(&:client_id)
      client_ids = @client_whitelist_objs.keys

      UserKycDetail.where(client_id: client_ids, status: GlobalConstant::UserKycDetail.active_status).
          kyc_admin_and_cynopsis_approved.# records which are approved by both admin and cynopsis
      whitelist_status_unprocessed.# records which are not yet processed for whitelisting
      find_in_batches(batch_size: 10) do |u_k_detail_objs|

        u_k_detail_objs.each do |user_kyc_detail|
          begin

            init_iteration_params(user_kyc_detail)

            # acquire lock over user_kyc_detail
            start_processing_whitelisting

            construct_api_data

            # make the API call to private ops API for whitelisting
            r = make_whitelist_api_call

            # move to next record in case of api failures
            next unless r.success?

            create_kyc_whitelist_log

          rescue => e
            Rails.logger.info("Exception: #{e.inspect}")
            handle_whitelist_error("Exception - #{e.inspect}", {exception: e})
          end

        end

      end

    end

    private

    # init iteration params
    #
    # * Author: Kedar, Alpesh
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    # @params [UserKycDetail]
    #
    # Sets @api_data, @user_kyc_detail
    #
    def init_iteration_params(user_kyc_detail)
      @api_data = {}
      @user_kyc_detail = user_kyc_detail
      @transaction_hash = nil
    end

    # start processing whitelisting
    #
    # * Author: Kedar, Alpesh
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    # @params [UserKycDetail]
    #
    def start_processing_whitelisting
      Rails.logger.info("user_kyc_detail id:: #{@user_kyc_detail.id} - started processing whilelisting")
      @user_kyc_detail.whitelist_status = GlobalConstant::UserKycDetail.started_whitelist_status
      @user_kyc_detail.kyc_confirmed_at = nil
      @user_kyc_detail.record_timestamps = false
      @user_kyc_detail.save!
    end

    # Construct API data
    #
    # * Author: Kedar, Alpesh
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    # Sets @api_data
    #
    def construct_api_data
      @api_data = {
          address: get_ethereum_address,
          whitelister_address: get_whitelister_address,
          phase: get_phase,
          contract_address: get_contract_address
      }
    end

    # Make API call
    #
    # * Author: Kedar, Alpesh
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def make_whitelist_api_call
      Rails.logger.info("user_kyc_detail id:: #{@user_kyc_detail.id} - making private ops api call")
      r = OpsApi::Request::Whitelist.new.whitelist({
                                                       whitelister_address: @api_data[:whitelister_address],
                                                       contract_address: @api_data[:contract_address],
                                                       address: @api_data[:address],
                                                       phase: @api_data[:phase]
                                                   })

      if r.success?
        @transaction_hash = r.data[:transaction_hash]
        @nonce = r.data[:nonce]
        @gas_price = r.data[:gas_price]

      else
        handle_whitelist_error('PrivateOpsApi Error', {private_ops_api_response: r.to_json})
      end

      r
    end

    # Create Kyc whitelist log
    #
    # * Author: Kedar, Alpesh
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    def create_kyc_whitelist_log
      KycWhitelistLog.create!({
                                  client_id: @user_kyc_detail.client_id,
                                  ethereum_address: @api_data[:address],
                                  phase: @api_data[:phase],
                                  transaction_hash: @transaction_hash,
                                  nonce: @nonce,
                                  gas_price: @gas_price,
                                  timestamp: Time.now.to_i + EXPECTED_CONFIRM_WAIT_INTERVAL,
                                  status: GlobalConstant::KycWhitelistLog.pending_status,
                                  is_attention_needed: 0
                              })
      Rails.logger.info("user_kyc_detail id:: #{@user_kyc_detail.id} - Creating entry in KycWhitelistLog")
    end

    # Get Decrypted ethereum address of user
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    # @return [String] Ethereum Address
    #
    def get_ethereum_address
      user_extended_detail = UserExtendedDetail.where(id: @user_kyc_detail.user_extended_detail_id).first
      kyc_salt_e = user_extended_detail.kyc_salt
      r = Aws::Kms.new('kyc', 'admin').decrypt(kyc_salt_e)
      kyc_salt_d = r.data[:plaintext]
      local_cipher_obj = LocalCipher.new(kyc_salt_d)
      local_cipher_obj.decrypt(user_extended_detail.ethereum_address).data[:plaintext]
    end

    # Get phase
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Integer] pahse
    #
    def get_phase
      UserKycDetail.token_sale_participation_phases[@user_kyc_detail.token_sale_participation_phase]
    end

    # Get contract address
    #
    # * Author: Aman
    # * Date: 29/12/2017
    # * Reviewed By:
    #
    # @return [String] contract address
    #
    def get_contract_address
      @client_whitelist_objs[@user_kyc_detail.client_id].contract_address
    end

    # Get get_whitelister_address address
    #
    # * Author: Aman
    # * Date: 15/01/2018
    # * Reviewed By:
    #
    # @return [String] whitelister_address of client
    #
    def get_whitelister_address
      @client_whitelist_objs[@user_kyc_detail.client_id].whitelister_address
    end

    # Handle whitelist errors
    #
    # * Author: Abhay
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    # @params [String] error_type
    # @params [Hash] error_data
    #
    def handle_whitelist_error(error_type, error_data)
      notify_devs(error_data, @user_kyc_detail.user_id)
      Rails.logger.info("user_kyc_detail id:: #{@user_kyc_detail.id} - Changing user_kyc_detail whitelist_status to failed")
      @user_kyc_detail.whitelist_status = GlobalConstant::UserKycDetail.failed_whitelist_status
      @user_kyc_detail.record_timestamps = false
      @user_kyc_detail.save!

      UserActivityLogJob.new().perform({
                                           user_id: @user_kyc_detail.user_id,
                                           action: GlobalConstant::UserActivityLog.kyc_whitelist_processor_error,
                                           action_timestamp: Time.now.to_i,
                                           extra_data: {
                                               user_kyc_detail_id: @user_kyc_detail.id,
                                               error_type: error_type,
                                               error_data: error_data
                                           }
                                       })
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
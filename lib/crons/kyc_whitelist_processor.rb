module Crons

  class KycWhitelistProcessor

    include Util::ResultHelper

    # initialize
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Crons::KycWhitelistProcessor]
    #
    def initialize(params)
      @shard_identifiers = params[:shard_identifiers].present? || GlobalConstant::Shard.shards_to_process_for_crons
      @api_data = {}
      @user_kyc_detail = nil
      @transaction_hash = nil
      @nonce = nil
      @gas_price = nil
      @all_clients = []
    end

    # public method to process hooks
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    def perform
      client_ids = ClientWhitelistDetail.not_suspended.
          where(status: GlobalConstant::ClientWhitelistDetail.active_status).pluck(:client_id)


      @shard_identifiers.each do |shard_identifier|

        UserKycDetail.using_shard(shard_identifier: shard_identifier).
            where(client_id: client_ids, status: GlobalConstant::UserKycDetail.active_status).
            kyc_admin_and_aml_approved.# records which are approved by both admin and aml
        whitelist_status_unprocessed.# records which are not yet processed for whitelisting
        find_in_batches(batch_size: 5) do |u_k_detail_objs|

          u_k_detail_objs.each do |user_kyc_detail|
            begin

              init_iteration_params(user_kyc_detail)

              # Ignore record if client whitelist detail is missing or suspended
              client_whitelist_detail = ClientWhitelistDetail.get_from_memcache(user_kyc_detail.client_id)
              next if client_whitelist_detail.blank? || !client_whitelist_detail.no_suspension_type?

              # acquire lock over user_kyc_detail
              start_processing_whitelisting

              construct_api_data

              # make the API call to private ops API for whitelisting
              r = make_whitelist_api_call(client_whitelist_detail)

              # move to next record in case of api failures
              next unless r.success?

              create_kyc_whitelist_log(client_whitelist_detail.id)

              record_event_job

            rescue => e
              Rails.logger.info("Exception: #{e.inspect}")
              handle_whitelist_error("Exception - #{e.inspect}", {exception: e})
            end

          end
          return if GlobalConstant::SignalHandling.sigint_received?
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
    # Sets @api_data, @user_kyc_detail, @client, @client_id
    #
    def init_iteration_params(user_kyc_detail)
      @api_data = {}
      @user_kyc_detail = user_kyc_detail
      @transaction_hash = nil
      @client_id = user_kyc_detail.client_id
      @client = fetch_client(@client_id)
    end

    # Fetch client from memcache once
    #
    # * Author: Aman
    # * Date: 25/01/2019
    # * Reviewed By:
    #
    def fetch_client(client_id)
      c = nil

      if @all_clients[client_id].present?
        c = @all_clients[client_id]
      else
        c = Client.get_from_memcache(client_id)
        @all_clients[client_id] = c
      end
      c
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
          phase: get_phase
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
    def make_whitelist_api_call(client_whitelist_detail)
      Rails.logger.info("user_kyc_detail id:: #{@user_kyc_detail.id} - making private ops api call")
      r = Request::OpsApi::Whitelist.new.whitelist({
                                                       whitelister_address: client_whitelist_detail.whitelister_address,
                                                       contract_address: client_whitelist_detail.contract_address,
                                                       address: @api_data[:address],
                                                       phase: @api_data[:phase],
                                                       gasPrice: EstimatedGasPrice::CurrentPrice.new.fetch
                                                   })

      if r.success?
        @transaction_hash = r.data[:transaction_hash]
        @nonce = r.data[:nonce]
        @gas_price = r.data[:gas_price]

      else
        client_whitelist_detail.mark_client_eth_balance_low if GlobalConstant::ClientWhitelistDetail.low_balance_error?(r.error)
        handle_whitelist_error('OpsApi Error', {private_ops_api_response: r.to_json})
      end

      r
    end

    # Create Kyc whitelist log
    #
    # * Author: Kedar, Alpesh
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    def create_kyc_whitelist_log(whitelist_detail_id)
      KycWhitelistLog.create!({
                                  client_id: @user_kyc_detail.client_id,
                                  ethereum_address: @api_data[:address],
                                  client_whitelist_detail_id: whitelist_detail_id,
                                  phase: @api_data[:phase],
                                  transaction_hash: @transaction_hash,
                                  nonce: @nonce,
                                  gas_price: @gas_price,
                                  next_timestamp: Time.now.to_i + GlobalConstant::KycWhitelistLog.expected_transaction_mine_time,
                                  status: GlobalConstant::KycWhitelistLog.pending_status,
                                  failed_reason: 0
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
      user_extended_detail = UserExtendedDetail.using_client_shard(client: @client).
          where(id: @user_kyc_detail.user_extended_detail_id).first
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
      UserKycDetail.using_client_shard(client: @client).
          token_sale_participation_phases[@user_kyc_detail.token_sale_participation_phase]
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
      @user_kyc_detail.whitelist_status = GlobalConstant::UserKycDetail.unprocessed_whitelist_status
      @user_kyc_detail.record_timestamps = false
      @user_kyc_detail.save!

      UserActivityLogJob.new().perform({
                                           client_id: @client_id,
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

    # record event for webhooks
    #
    # * Author: Tejas
    # * Date: 16/10/2018
    # * Reviewed By:
    #
    def record_event_job
      WebhookJob::RecordEvent.perform_now({
                                              client_id: @user_kyc_detail.client_id,
                                              event_source: GlobalConstant::Event.kyc_system_source,
                                              event_name: GlobalConstant::Event.kyc_status_update_name,
                                              event_data: {
                                                  user_kyc_detail: @user_kyc_detail.get_hash,
                                                  admin: @user_kyc_detail.get_last_acted_admin_hash
                                              },
                                              event_timestamp: Time.now.to_i
                                          })

    end

  end

end
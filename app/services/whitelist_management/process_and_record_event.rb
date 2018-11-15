module WhitelistManagement

  class ProcessAndRecordEvent < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    # @param [Hash] decoded_token_data (mandatory) - decoded token data
    #
    # @return [WhitelistManagement::ProcessAndRecordEvent]
    #
    def initialize(params)
      super

      @decoded_token_data = @params[:decoded_token_data]

      @transaction_hash, @block_hash, @ethereum_address, @phase = nil, nil, nil, nil

      @kyc_whitelist_log, @client_whitelist_obj, @user_id, @user_kyc_detail, @user = nil, nil, nil, nil, nil

      @block_number, @event_data, @contract_address = nil, nil, nil

      @client_id, @client = nil, nil
    end

    # Perform
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def perform
      begin

        r = validate_and_sanitize
        return r unless r.success?

        create_user_contract_event

        r = fetch_kyc_whitelisting_details
        return r unless r.success?

        r = validate_kyc_whitelist_log
        return r unless r.success?

        update_kyc_whitelist_log

        update_user_kyc_detail(GlobalConstant::UserKycDetail.done_whitelist_status)

        success

      rescue => e
        notify_devs({exception: e, backtrace: e.backtrace})
        return error_with_data(
            'wm_pare_1',
            'exception',
            'exception',
            GlobalConstant::ErrorAction.default,
            {}
        )
      end
    end

    private

    # Validate and sanitize
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    # Sets @transaction_hash, @block_hash, @ethereum_address, @phase, @block_number, @event_data, @contract_address
    #
    # @return [Result::Base]
    #
    def validate_and_sanitize

      r = validate
      unless r.success?
        notify_devs({decoded_token_data: @decoded_token_data})
        return r
      end

      @transaction_hash = @decoded_token_data[:transaction_hash]
      @block_hash = @decoded_token_data[:block_hash]
      @block_number = @decoded_token_data[:block_number].to_i

      (@decoded_token_data[:events_data] || []).each do |e|
        next if e.blank?

        if e[:name] == GlobalConstant::ContractEvent.whitelist_updated_kind

          @contract_address = e[:address]
          @event_data = e[:events]

        end
      end

      return error_with_data(
          'wm_pare_2',
          'invalid event data',
          'invalid event data',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @event_data.blank? || !@event_data.is_a?(Array)

      return error_with_data(
          'wm_pare_2.1',
          'invalid contract_address',
          'invalid contract_address',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @contract_address.blank?

      @event_data.each do |var_obj|
        case var_obj[:name]
          when '_account'
            @ethereum_address = var_obj[:value]
          when '_phase'
            _phase = var_obj[:value]
            return error_with_data(
                'wm_pare_2.1',
                "invalid phase value: #{_phase}",
                "invalid phase value: #{_phase}",
                GlobalConstant::ErrorAction.default,
                {}
            ) unless Util::CommonValidateAndSanitize.is_float?(_phase)

            @phase = _phase.to_i
        end
      end

      return error_with_data(
          'wm_pare_2.2',
          'invalid event data',
          'invalid event data',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @phase.nil? || @ethereum_address.blank?

      success
    end

    # create user_contract_event
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    def create_user_contract_event
      contract_event_obj = ContractEvent.where(
          transaction_hash: @transaction_hash,
          kind: GlobalConstant::ContractEvent.whitelist_updated_kind,
          contract_address: @contract_address
      ).first

      contract_event_status = GlobalConstant::ContractEvent.processed_status

      if contract_event_obj.present?
        return if contract_event_obj.block_hash.downcase == @block_hash.downcase
        contract_event_status = GlobalConstant::ContractEvent.duplicate_status
      end

      ContractEvent.create!({
                                block_hash: @block_hash,
                                transaction_hash: @transaction_hash,
                                block_number: @block_number,
                                kind: GlobalConstant::ContractEvent.whitelist_updated_kind,
                                contract_address: @contract_address,
                                status: contract_event_status,
                                data: {event_data: @event_data}
                            })
    end

    # Fetch kyc whitelist log
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    # Sets @kyc_whitelist_log, @client_whitelist_obj
    #
    # @return [Result::Base]
    #
    def fetch_kyc_whitelisting_details
      @kyc_whitelist_log = KycWhitelistLog.where(transaction_hash: @transaction_hash).first

      if @kyc_whitelist_log.blank?
        notify_devs({transaction_hash: @transaction_hash}, "IMMEDIATE ATTENTION NEEDED. transaction_hash not found")

        return error_with_data(
            'wm_pare_2',
            'transaction_hash not found',
            'transaction_hash not found',
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

      @client_whitelist_obj = ClientWhitelistDetail.get_from_memcache(@kyc_whitelist_log.client_id)

      return error_with_data(
          'wm_pare_2.2',
          'Contract Address used for whitelist does not match',
          'Contract Address used for whitelist does not match',
          GlobalConstant::ErrorAction.default,
          {}
      ) if @client_whitelist_obj.blank? || @client_whitelist_obj.contract_address.downcase != @contract_address.downcase

      r = fetch_user_kyc_detail
      return r unless r.success?

      success
    end

    # Validate kyc whitelist log record
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def validate_kyc_whitelist_log

      if (@kyc_whitelist_log.ethereum_address.downcase != @ethereum_address.downcase) ||
          (@kyc_whitelist_log.phase != @phase)

        @kyc_whitelist_log.mark_failed_with_reason(GlobalConstant::KycWhitelistLog.invalid_event_received)
        update_user_kyc_detail(GlobalConstant::UserKycDetail.failed_whitelist_status)

        notify_devs(
            {ethereum_address: @ethereum_address, phase: @phase, transaction_hash: @transaction_hash},
            "IMMEDIATE ATTENTION NEEDED. ethereum address or phase mismatch"
        )

        return error_with_data(
            'wm_pare_3',
            'ethereum address or phase mismatch',
            'ethereum address or phase mismatch',
            GlobalConstant::ErrorAction.default,
            {}
        )

      end

      if @kyc_whitelist_log.failed_reason != GlobalConstant::KycWhitelistLog.not_failed
        notify_devs(
            {ethereum_address: @ethereum_address, phase: @phase,
             transaction_hash: @transaction_hash, failed_reason: @kyc_whitelist_log.failed_reason},
            "IMMEDIATE ATTENTION NEEDED. Kyc Log already marked as failed."
        )

        return error_with_data(
            'wm_pare_4',
            "already marked failed with reason #{@kyc_whitelist_log.failed_reason}",
            "already marked failed with reason #{@kyc_whitelist_log.failed_reason}",
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

      if [GlobalConstant::KycWhitelistLog.pending_status, GlobalConstant::KycWhitelistLog.done_status].exclude?(@kyc_whitelist_log.status)
        notify_devs(
            {ethereum_address: @ethereum_address, phase: @phase, transaction_hash: @transaction_hash, kyc_whitelist_log_id: @kyc_whitelist_log.id},
            "IMMEDIATE ATTENTION NEEDED. kyc_whitelist_log status not pending or done, still record event called."
        )

        return error_with_data(
            'wm_pare_5',
            'kyc_whitelist_log status not pending or done, still record event called.',
            'kyc_whitelist_log status not pending or done, still record event called.',
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

      success
    end

    # Fetch user kyc detail
    #
    # * Author: Kedar, Alpesh
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    # Sets @user_id, @user_kyc_detail, @user, @client_id, @client
    #
    # @return [Result::Base]
    #
    def fetch_user_kyc_detail

      user_kyc_details = Md5UserExtendedDetail.get_user_kyc_details(@kyc_whitelist_log.client_id, @kyc_whitelist_log.ethereum_address)

      if user_kyc_details.blank?
        @kyc_whitelist_log.mark_failed_with_reason(GlobalConstant::KycWhitelistLog.invalid_kyc_record)

        notify_devs(
            {ethereum_address: @ethereum_address, phase: @phase, transaction_hash: @transaction_hash},
            "IMMEDIATE ATTENTION NEEDED. no approved user_kyc_detail records found for address"
        )

        return error_with_data(
            'wm_pare_7',
            'no approved user_kyc_detail records found for address.',
            'no approved user_kyc_detail records found for address',
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

      if user_kyc_details.count > 1
        @kyc_whitelist_log.mark_failed_with_reason(GlobalConstant::KycWhitelistLog.invalid_kyc_record)

        notify_devs(
            {ethereum_address: @ethereum_address, phase: @phase, transaction_hash: @transaction_hash},
            "IMMEDIATE ATTENTION NEEDED. multiple approved user_kyc_detail records found for same address"
        )

        return error_with_data(
            'wm_pare_8',
            'multiple approved user_kyc_detail records found for same address.',
            'multiple approved user_kyc_detail records found for same address',
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

      @user_kyc_detail = user_kyc_details.first

      if @kyc_whitelist_log.phase == 0 && [GlobalConstant::UserKycDetail.unprocessed_whitelist_status,
                          GlobalConstant::UserKycDetail.started_whitelist_status].include?(@user_kyc_detail.whitelist_status)
        @kyc_whitelist_log.mark_failed_with_reason(GlobalConstant::KycWhitelistLog.invalid_kyc_record)
        notify_devs(
            {ethereum_address: @ethereum_address, phase: @phase, transaction_hash: @transaction_hash},
            "IMMEDIATE ATTENTION NEEDED. if phase is 0 then whitelist status should be done or failed only"
        )
        return error_with_data(
            'wm_pare_9',
            'if phase is 0 then whitelist status should be done or failed only',
            'if phase is 0 then whitelist status should be done or failed only',
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

      if @kyc_whitelist_log.phase > 0 && [GlobalConstant::UserKycDetail.started_whitelist_status, GlobalConstant::UserKycDetail.done_whitelist_status].exclude?(@user_kyc_detail.whitelist_status)
        @kyc_whitelist_log.mark_failed_with_reason(GlobalConstant::KycWhitelistLog.invalid_kyc_record)
        notify_devs(
            {ethereum_address: @ethereum_address, phase: @phase, transaction_hash: @transaction_hash},
            "IMMEDIATE ATTENTION NEEDED. invalid whitelist status"
        )

        return error_with_data(
            'wm_pare_10',
            'invalid whitelist status',
            'invalid whitelist status',
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

      @user_id = @user_kyc_detail.user_id
      @client_id = @user_kyc_detail.client_id

      @user = User.get_from_memcache(@user_kyc_detail.user_id)
      @client = Client.get_from_memcache(@client_id)
      success

    end

    # update kyc_whitelist_log
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    def update_kyc_whitelist_log
      @kyc_whitelist_log.status = GlobalConstant::KycWhitelistLog.done_status
      @kyc_whitelist_log.next_timestamp = Time.now.to_i + GlobalConstant::KycWhitelistLog.confirm_wait_interval
      @kyc_whitelist_log.save! if @kyc_whitelist_log.changed?
    end

    # update update user kyc details
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    def update_user_kyc_detail(whitelist_status)
      # phase with 0 value can come in callback event for unwhitelisting .
      # whitelisting can't be confirmed if @phase = 0
      return if @kyc_whitelist_log.phase == 0

      @user_kyc_detail.whitelist_status = whitelist_status
      if @user_kyc_detail.whitelist_status_changed? &&
          @user_kyc_detail.whitelist_status == GlobalConstant::UserKycDetail.done_whitelist_status
        send_kyc_approved_mail
      end

      @user_kyc_detail.record_timestamps = false
      if @user_kyc_detail.changed?
        @user_kyc_detail.save!
        enqueue_job
      end
    end

    # Send Email when kyc whitelist status is done without creating hooks if email was not previously sent
    # Note: In case of error use hooks to send email
    #
    # * Author: Aman
    # * Date: 04/11/2017
    # * Reviewed By: Sunil
    #
    def send_kyc_approved_mail

      return if !@client.is_email_setup_done? || @client.is_st_token_sale_client?

      fetch_client_token_sale_details

      emails_hook_info = EmailServiceApiCallHook.get_emails_hook_info(
          @client.id, GlobalConstant::PepoCampaigns.kyc_approved_template, [@user.email])

      return if emails_hook_info.present? && emails_hook_info[@user.email].present?

      return if (KycWhitelistLog.where(client_id: @client_id, ethereum_address: @ethereum_address, status:
                                                                [GlobalConstant::KycWhitelistLog.done_status, GlobalConstant::KycWhitelistLog.confirmed_status]).count > 1)

      send_mail_response = pepo_campaign_obj.send_transactional_email(
          @user.email, GlobalConstant::PepoCampaigns.kyc_approved_template, kyc_approved_template_vars.merge(@client.web_host_params))

      send_kyc_approved_mail_via_hooks if send_mail_response['error'].present?

    end

    # Fetch token sale details
    #
    # * Author: Aman
    # * Date: 01/02/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def fetch_client_token_sale_details
      @client_token_sale_details = ClientTokenSaleDetail.get_from_memcache(@client_id)
    end

    # pepo campaign klass
    #
    # * Author: Aman
    # * Date: 02/01/2018
    # * Reviewed By:
    #
    # @return [Object] Email::Services::PepoCampaigns
    def pepo_campaign_obj
      @pepo_campaign_obj ||= begin
        client_campaign_detail = ClientPepoCampaignDetail.get_from_memcache(@client_id)

        r = Aws::Kms.new('saas', 'saas').decrypt(@client.api_salt)
        return r unless r.success?

        api_salt_d = r.data[:plaintext]

        r = LocalCipher.new(api_salt_d).decrypt(client_campaign_detail.api_secret)
        return r unless r.success?

        api_secret_d = r.data[:plaintext]

        Email::Services::PepoCampaigns.new(api_key: client_campaign_detail.api_key, api_secret: api_secret_d)
      end

    end

    # KYC approved email transactional var data
    #
    # * Author: Aman
    # * Date: 04/11/2017
    # * Reviewed By: Sunil
    #
    # @return [Hash] variable data for transactional email
    #
    def kyc_approved_template_vars
      {
          token_sale_participation_phase: @user_kyc_detail.token_sale_participation_phase,
          is_sale_active: @client_token_sale_details.has_token_sale_started?
      }
    end

    # Send Email via hook processor
    #
    # * Author: Aman
    # * Date: 04/11/2017
    # * Reviewed By: Sunil
    #
    def send_kyc_approved_mail_via_hooks

      Email::HookCreator::SendTransactionalMail.new(
          client_id: @client_id,
          email: @user.email,
          template_name: GlobalConstant::PepoCampaigns.kyc_approved_template,
          template_vars: kyc_approved_template_vars
      ).perform
    end

    # Handle error
    #
    # * Author: Abhay
    # * Date: 28/10/2017
    # * Reviewed By: Sunil
    #
    def handle_error(user_kyc_whitelist_log, error_type, error_data)
      notify_devs({transaction_hash: @transaction_hash, user_id: @user_id}, error_type)
      UserActivityLogJob.new().perform({
                                           user_id: @user.id,
                                           action: GlobalConstant::UserActivityLog.kyc_whitelist_attention_needed,
                                           action_timestamp: Time.now.to_i,
                                           extra_data: {
                                               error_type: error_type,
                                               user_kyc_whitelist_log_id: user_kyc_whitelist_log.id,
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
    def notify_devs(error_data, subject='Error while WhitelistManagement::ProcessAndRecordEvent')
      ApplicationMailer.notify(
          body: {},
          data: {error_data: error_data},
          subject: subject
      ).deliver
    end

    # Do remaining task in sidekiq
    #
    # * Author: Tejas
    # * Date: 16/10/2018
    # * Reviewed By:
    #
    def enqueue_job
      BgJob.enqueue(
          WebhookJob::RecordEvent,
          {
              client_id: @user_kyc_detail.client_id,
              event_source: GlobalConstant::Event.kyc_system_source,
              event_name: GlobalConstant::Event.kyc_status_update_name,
              event_data: {
                  user_kyc_detail: @user_kyc_detail.get_hash,
                  admin: @user_kyc_detail.get_last_acted_admin_hash
              },
              event_timestamp: Time.now.to_i
          }
      )

    end

  end

end
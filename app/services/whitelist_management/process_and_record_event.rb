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

      @kyc_whitelist_log, @user_id, @user_kyc_detail, @user = nil, nil, nil, nil

      @block_number, @event_data, @contract_address = nil, nil, nil
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

        r = fetch_kyc_whitelist_log
        return r unless r.success?

        r = validate_kyc_whitelist_log
        return r unless r.success?

        r = get_prospective_user_extended_detail_ids
        return r unless r.success?

        r = fetch_user_kyc_detail(r.data[:prospective_user_extended_detail_ids])
        unless r.success?
          mark_as_attention_required
          return r
        end

        update_kyc_whitelist_log

        update_user_kyc_detail

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
        if (GlobalConstant::StFoundationContract.token_sale_contract_address == e[:address]) &&
          (e[:name] == GlobalConstant::ContractEvent.whitelist_updated_kind)

          @contract_address = GlobalConstant::StFoundationContract.token_sale_contract_address
          @event_data = e[:events]

        end
      end

      return error_with_data(
        'wm_pare_2',
        'invalid event data',
        'invalid event data',
        GlobalConstant::ErrorAction.default,
        {}
      ) unless @event_data.present?

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
            ) unless Util::CommonValidator.is_numeric?(_phase)

            @phase = _phase.to_i
        end
      end

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
                                contract_address:@contract_address,
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
    # Sets @kyc_whitelist_log
    #
    # @return [Result::Base]
    #
    def fetch_kyc_whitelist_log
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

        mark_as_attention_required

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

      if @kyc_whitelist_log.is_attention_needed == 1
        notify_devs(
            {ethereum_address: @ethereum_address, phase: @phase, transaction_hash: @transaction_hash},
            "IMMEDIATE ATTENTION NEEDED. already found is_attention_needed = 1"
        )

        return error_with_data(
            'wm_pare_4',
            'already found is_attention_needed = 1',
            'already found is_attention_needed = 1',
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

      if @kyc_whitelist_log.status != GlobalConstant::KycWhitelistLog.pending_status
        notify_devs(
            {ethereum_address: @ethereum_address, phase: @phase, transaction_hash: @transaction_hash},
            "IMMEDIATE ATTENTION NEEDED. kyc_whitelist_log status not pending, still record event called."
        )

        return error_with_data(
            'wm_pare_5',
            'kyc_whitelist_log status not pending, still record event called.',
            'kyc_whitelist_log status not pending, still record event called.',
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

      success
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
          ethereum_address: Md5UserExtendedDetail.get_hashed_value(@ethereum_address)
      ).pluck(:user_extended_detail_id)

      if prospective_user_extended_detail_ids.blank?
        notify_devs(
            {ethereum_address: @ethereum_address, phase: @phase, transaction_hash: @transaction_hash},
            "IMMEDIATE ATTENTION NEEDED. no user_extended_detail_id found, still record event called."
        )

        return error_with_data(
            'wm_pare_6',
            'kyc_whitelist_log status not pending, still record event called.',
            'kyc_whitelist_log status not pending, still record event called.',
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
    # Sets @user_id, @user_kyc_detail, @user
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
            'wm_pare_7',
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
            'wm_pare_8',
            'multiple approved user_kyc_detail records found for same address.',
            'multiple approved user_kyc_detail records found for same address',
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

      @user_kyc_detail = user_kyc_details.first

      if @user_kyc_detail.whitelist_status != GlobalConstant::UserKycDetail.started_whitelist_status
        notify_devs(
            {ethereum_address: @ethereum_address, phase: @phase, transaction_hash: @transaction_hash},
            "IMMEDIATE ATTENTION NEEDED. invalid whitelist status"
        )

        return error_with_data(
            'wm_pare_9',
            'invalid whitelist status',
            'invalid whitelist status',
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

      # Skip this validation for phase 0
      if (@phase != 0) && (UserKycDetail.token_sale_participation_phases[@user_kyc_detail.token_sale_participation_phase] != @phase)
        notify_devs(
            {ethereum_address: @ethereum_address, phase: @phase, transaction_hash: @transaction_hash},
            "IMMEDIATE ATTENTION NEEDED. phase mismatch"
        )

        return error_with_data(
            'wm_pare_10',
            'phase mismatch',
            'phase mismatch',
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

      @user_id = @user_kyc_detail.user_id
      @user = User.get_from_memcache(@user_kyc_detail.user_id)

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
      @kyc_whitelist_log.save! if @kyc_whitelist_log.changed?
    end

    # update update user kyc details
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    def update_user_kyc_detail
      # phase with 0 value can come in callback event for unwhitelisting .
      # whitelisting can't be confirmed if @phase = 0
      return if @phase == 0

      @user_kyc_detail.whitelist_status = GlobalConstant::UserKycDetail.done_whitelist_status
      if @user_kyc_detail.whitelist_status_changed? &&
          @user_kyc_detail.whitelist_status == GlobalConstant::UserKycDetail.done_whitelist_status
        send_kyc_approved_mail
      end

      @user_kyc_detail.record_timestamps = false
      @user_kyc_detail.save! if @user_kyc_detail.changed?
    end

    # Mark as attention required
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    def mark_as_attention_required
      @kyc_whitelist_log.is_attention_needed = GlobalConstant::KycWhitelistLog.attention_needed
      @kyc_whitelist_log.save! if @kyc_whitelist_log.changed?
    end

    # Send Email when kyc whitelist status is done without creating hooks if email was not previously sent
    # Note: In case of error use hooks to send email
    #
    # * Author: Aman
    # * Date: 04/11/2017
    # * Reviewed By: Sunil
    #
    def send_kyc_approved_mail

      return if GlobalConstant::TokenSale.is_sale_ended?

      emails_hook_info = EmailServiceApiCallHook.get_emails_hook_info(
        GlobalConstant::PepoCampaigns.kyc_approved_template, [@user.email])

      return if emails_hook_info.present? && emails_hook_info[@user.email].present?

      return if (KycWhitelistLog.where(ethereum_address: @ethereum_address, status:
        [GlobalConstant::KycWhitelistLog.done_status, GlobalConstant::KycWhitelistLog.confirmed_status]).count > 1)

      send_mail_response = Email::Services::PepoCampaigns.new.send_transactional_email(
        @user.email, GlobalConstant::PepoCampaigns.kyc_approved_template, kyc_approved_template_vars)

      send_kyc_approved_mail_via_hooks if send_mail_response['error'].present?

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
          is_sale_active: GlobalConstant::TokenSale.is_general_sale_interval?
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

  end

end
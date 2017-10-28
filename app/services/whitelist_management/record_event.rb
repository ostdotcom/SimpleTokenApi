module WhitelistManagement

  class RecordEvent < ServicesBase

    # Initialize
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    # @param [Hash] decoded_token_data (mandatory) - decoded token data
    #
    # @return [WhitelistManagement::RecordEvent]
    #
    def initialize(params)
      super

      @decoded_token_data = @params[:decoded_token_data]

      @transaction_hash, @block_hash, @ethereum_address, @user_phase = nil, nil, nil, nil

      @user_kyc_whitelist_log, @user_id, @user_kyc_detail, @user = nil, nil, nil, nil

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

        r = get_user_kyc_related_details
        return r unless r.success?

        create_user_contract_event

        r = verify_transaction_data
        return r unless r.success?

        update_user_kyc_whitelist_log

        update_user_kyc_detail

        success
      rescue => e
        notify_devs({exception: e, backtrace: e.backtrace})
        return error_with_data(
            'wm_re_3',
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
    # Sets @transaction_hash, @block_hash, @ethereum_address, @user_phase
    #
    # @return [Result::Base]
    #
    def validate_and_sanitize

      r = validate
      if !r.success?
        notify_devs({decoded_token_data: @decoded_token_data})
        return r
      end

      @transaction_hash = @decoded_token_data[:transaction_hash]
      @block_hash = @decoded_token_data[:block_hash]
      event_data = (@decoded_token_data[:event_data] || {})
      @ethereum_address = event_data[:address]
      @user_phase = event_data[:phase]

      success
    end

    # get user kyc related details
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    # Sets @user_kyc_whitelist_log, @user_id, @user_kyc_detail, @user
    #
    def get_user_kyc_related_details
      @user_kyc_whitelist_log = UserKycWhitelistLog.where(transaction_hash: @transaction_hash).first

      if @user_kyc_whitelist_log.blank?
        notify_devs({transaction_hash: @transaction_hash}, "IMMEDIATE ATTENTION NEEDED.transaction_hash not found")

        return error_with_data(
            'wm_re_1',
            'transaction_hash not found',
            'transaction_hash not found',
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

      @user_id = @user_kyc_whitelist_log.user_id
      @user_kyc_detail = UserKycDetail.where(user_id: @user_id).first
      @user = User.where(id: @user_kyc_detail.user_id).first

      success
    end

    # create user_contract_event
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    def create_user_contract_event
      UserContractEvent.create!({
                                    user_id: @user_kyc_detail.user_id,
                                    block_hash: @block_hash,
                                    transaction_hash: @transaction_hash,
                                    kind: GlobalConstant::UserContractEvent.whitelist_kind
                                })
    end

    # Verify transaction contract data
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Result::Base]
    #
    def verify_transaction_data
      return success if is_phase_valid? && is_ethereum_address_valid? && @user_kyc_detail.kyc_approved?

      @user_kyc_whitelist_log.is_attention_needed = GlobalConstant::UserKycWhitelistLog.attention_needed
      @user_kyc_whitelist_log.save! if @user_kyc_whitelist_log.changed?

      if !@user_kyc_detail.kyc_approved?
        error_type = "user_kyc_detail - #{@user_kyc_detail.id} is not approved"
      else
        error_type= "Invalid contract event data"
      end
      handle_error(@user_kyc_whitelist_log, error_type, {decoded_token_data: @decoded_token_data})

      error_with_data(
          'wm_re_2',
          error_type,
          error_type,
          GlobalConstant::ErrorAction.default,
          {}
      )

    end

    # Is phase valid
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Boolean]
    #
    def is_phase_valid?
      UserKycDetail.token_sale_participation_phases[@user_kyc_detail.token_sale_participation_phase] == @user_phase.to_i
    end

    # Is ethereum address valid
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    # @return [Boolean]
    #
    def is_ethereum_address_valid?
      obtained_addr_md5 = Digest::MD5.hexdigest(@ethereum_address.to_s.downcase.strip)
      actual_addr_md5 = Md5UserExtendedDetail.where(user_extended_detail_id: @user_kyc_detail.user_extended_detail_id).first.ethereum_address
      return obtained_addr_md5 == actual_addr_md5
    end

    # update update_user_kyc_whitelist obj
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    def update_user_kyc_whitelist_log

      if @user_kyc_whitelist_log.status == GlobalConstant::UserKycWhitelistLog.pending_status
        @user_kyc_whitelist_log.status = GlobalConstant::UserKycWhitelistLog.done_status
      else
        @user_kyc_whitelist_log.is_attention_needed = GlobalConstant::UserKycWhitelistLog.attention_needed
        handle_error(@user_kyc_whitelist_log, 'duplicate event success response', {decoded_token_data: @decoded_token_data})
      end
      @user_kyc_whitelist_log.save! if @user_kyc_whitelist_log.changed?

    end

    # update update user kyc details
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    def update_user_kyc_detail
      @user_kyc_detail.whitelist_status = GlobalConstant::UserKycDetail.done_whitelist_status
      if @user_kyc_detail.whitelist_status_changed? && @user_kyc_detail.whitelist_status == GlobalConstant::UserKycDetail.done_whitelist_status
        send_kyc_approved_email
      end

      @user_kyc_detail.save! if @user_kyc_detail.changed?
    end

    # Send Email when kyc whitelist status is done
    #
    # * Author: Abhay
    # * Date: 26/10/2017
    # * Reviewed By: Sunil
    #
    def send_kyc_approved_email
      return if GlobalConstant::TokenSale.is_general_sale_ended?

      Email::HookCreator::SendTransactionalMail.new(
          email: @user.email,
          template_name: GlobalConstant::PepoCampaigns.kyc_approved_template,
          template_vars: {
              token_sale_participation_phase: @user_kyc_detail.token_sale_participation_phase,
              is_sale_active: GlobalConstant::TokenSale.is_general_sale_interval?
          }
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
    def notify_devs(error_data, subject='Error while WhitelistManagement::RecordEvent')
      ApplicationMailer.notify(
          body: {},
          data: {error_data: error_data},
          subject: subject
      ).deliver
    end

  end

end
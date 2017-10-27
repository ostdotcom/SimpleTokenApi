module WhitelistManagement

  class RecordEvent < ServicesBase

    require 'jwt'

    # Initialize
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    # @param [String] token (mandatory) - encrypted token
    #
    # @return [WhitelistManagement::RecordEvent]
    #
    def initialize(params)
      super

      @token = @params[:token]

      @transaction_hash, @block_hash, @ethereum_address, @user_phase = nil, nil, nil, nil

      @user_kyc_whitelist_log, @user_id, @user_kyc_detail = nil, nil, nil

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

      r = validate
      (notify_devs({}) and return r) unless r.success?

      begin

        decrypt_token

        r = get_user_kyc_whitelist_log
        return r unless r.success?

        create_user_contract_event

        r = verify_transaction_data
        return r unless r.success?

        update_user_kyc_whitelist

        success
      rescue => e
        notify_devs({exception: e})
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

    # decrypt token
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By:
    #
    # Sets @transaction_hash, @block_hash, @ethereum_address, @user_phase
    #
    def decrypt_token
      decoded_data = JWT.decode(@token, GlobalConstant::PublicOpsApi.secret_key, true, {:algorithm => 'HS256'})[0]["data"]
      @transaction_hash = decoded_data["transaction_hash"]
      @block_hash = decoded_data["block_hash"]
      @ethereum_address = decoded_data["event_data"]["address"]
      @user_phase = decoded_data["event_data"]["phase"]
    end

    # get user kyc whitelist log and user details
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By:
    #
    # Sets @user_kyc_whitelist_log, @user_id, @user_kyc_detail
    #
    def get_user_kyc_whitelist_log
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

      success
    end

    # create user_contract_event
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By:
    #
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
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def verify_transaction_data
      return success if ((UserKycDetail.token_sale_participation_phases[@user_kyc_detail.token_sale_participation_phase] == @user_phase.to_i) && (@ethereum_address.downcase == get_ethereum_address.downcase))

      notify_devs({transaction_hash: @transaction_hash}, "IMMEDIATE ATTENTION NEEDED. Invalid event contract data")

      @user_kyc_whitelist_log.attention_needed = GlobalConstant::UserKycWhitelistLog.attention_needed
      @user_kyc_whitelist_log.save! if @user_kyc_whitelist_log.changed?

      return error_with_data(
          'wm_re_2',
          'Invalid event contract data',
          'Invalid event contract data',
          GlobalConstant::ErrorAction.default,
          {}
      )

    end

    # Get Decrypted ethereum address of user
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By:
    #
    def get_ethereum_address
      user_extended_detail = UserExtendedDetail.where(id: @user_kyc_detail.user_extended_detail_id).first
      kyc_salt_e = user_extended_detail.kyc_salt
      r = Aws::Kms.new('kyc', 'admin').decrypt(kyc_salt_e)
      kyc_salt_d = r.data[:plaintext]
      local_cipher_obj = LocalCipher.new(kyc_salt_d)
      local_cipher_obj.decrypt(user_extended_detail.ethereum_address).data[:plaintext]
    end

    # update update_user_kyc_whitelist obj
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By:
    #
    #
    def update_user_kyc_whitelist

      if @user_kyc_whitelist_log.status == GlobalConstant::UserKycWhitelistLog.pending_status
        @user_kyc_whitelist_log.status = GlobalConstant::UserKycWhitelistLog.done_status

      else
        notify_devs(
            {transaction_hash: @transaction_hash, user_id: @user_id},
            "ATTENTION NEEDED.duplicate event success response")
        @user_kyc_whitelist_log.attention_needed = GlobalConstant::UserKycWhitelistLog.attention_needed
      end
      @user_kyc_whitelist_log.save! if @user_kyc_whitelist_log.changed?

      @user_kyc_detail.whitelist_status = GlobalConstant::UserKycDetail.done_whitelist_status
      if @user_kyc_detail.whitelist_status_changed? && @user_kyc_detail.whitelist_status == GlobalConstant::UserKycDetail.done_whitelist_status
        send_email
      end

      if @user_kyc_detail.changed?
        @user_kyc_detail.save!
      end

    end

    # Send Email when kyc whitelist status is done
    #
    # * Author: Abhay
    # * Date: 26/10/2017
    # * Reviewed By:
    #
    def send_email
      @user = User.where(id: @user_kyc_detail.user_id).first

      Email::HookCreator::SendTransactionalMail.new(
          email: @user.email,
          template_name: GlobalConstant::PepoCampaigns.kyc_approved_template,
          template_vars: {
              token_sale_participation_phase: @user_kyc_detail.token_sale_participation_phase,
              is_sale_active: (Time.now >= GlobalConstant::TokenSale.general_access_start_date)
          }
      ).perform
    end

    # notify devs if required
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By:
    #
    def notify_devs(error_data, subject='Error while WhitelistManagement::RecordEvent')
      ApplicationMailer.notify(
          body: {token: @token},
          data: {error_data: error_data},
          subject: subject
      ).deliver
    end


  end

end
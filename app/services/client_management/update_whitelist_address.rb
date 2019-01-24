module ClientManagement
  class UpdateWhitelistAddress < ServicesBase

    # Initialize
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    # @param [Integer] client_id (mandatory) -  client id
    # @param [Integer] admin_id (mandatory) -  admin id
    # @param [String] whitelist_address (mandatory) -  whitelist address
    # @param [String] otp (mandatory) -  otp
    # @param [Boolean] rewhitelist (optional) -  rewhitelist all whitelisted users
    #
    # @return [ClientManagement::UpdateWhitelistAddress]
    #
    def initialize(params)
      super

      @client_id = @params[:client_id]
      @admin_id = @params[:admin_id]
      @whitelist_contract_address = @params[:whitelist_contract_address]
      @otp = @params[:otp].to_s
      @rewhitelist = @params[:rewhitelist]

      @client_whitelist_detail = nil
      @admin_secret_obj = nil
      @active_client_whitelist_detail_obj = nil
    end

    # Perform
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform

      r = validate_and_sanitize
      return r unless r.success?

      r = fetch_admin_secret_obj
      return r unless r.success?

      r = validate_otp
      return r unless r.success?

      r = validate_whitelist_address
      return r unless r.success?

      fetch_client_whitelist_detail

      r = set_whitelist_contract_address
      return r unless r.success?

      send_email

      enqueue_job_for_rewhitelist_users

      success_with_data(success_response_data)
    end


    private

    # Validate And Sanitize
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    #
    def validate_and_sanitize
      r = validate
      return r unless r.success?

      r = validate_client_and_admin
      return r unless r.success?

      r = validate_client_whitelisting_plan
      return r unless r.success?

      success
    end

    # Client and Admin validate
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    # sets @admin, @client
    #
    def validate_client_and_admin
      r = fetch_and_validate_client
      return r unless r.success?

      r = fetch_and_validate_admin
      return r unless r.success?

      success
    end

    # Validate Client Whitelisting Plan
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    def validate_client_whitelisting_plan
      client_plan = ClientPlan.get_client_plan_from_memcache(@client_id)

      return error_with_identifier('forbidden_api_request', 'cm_uwa_vcwp_1') if client_plan.add_ons_array.exclude?(GlobalConstant::ClientPlan.whitelist_add_ons)
      success
    end

    # Validate Whitelist Address
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    # sets @client_whitelist_detail, kyc_whitelist_log, edit_kyc_request
    # @return [Result::Base]
    #
    def validate_whitelist_address

      @whitelist_contract_address = Util::CommonValidator.sanitize_ethereum_address(@whitelist_contract_address)

      return error_with_identifier('invalid_api_params',
                                   'cm_uwa_vwa_1',
                                   ['invalid_whitelist_contract_address'],
                                   'There were some errors in address submission. Please review and resubmit'
      ) if !(Util::CommonValidator.is_ethereum_address?(@whitelist_contract_address))

      is_whitelist_transaction_pending = KycWhitelistLog.kyc_whitelist_non_confirmed.where(client_id: @client_id).exists?

      return error_with_identifier('whitelist_transaction_pending',
                                   'cm_uwa_vwa_2') if is_whitelist_transaction_pending

      success
    end

    # fetch admin secret obj
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    # sets @admin_secret_obj
    #
    # @return [Result::Base]
    #
    def fetch_admin_secret_obj
      @admin_secret_obj = AdminSecret.get_from_memcache(@admin.admin_secret_id)

      success
    end

    # Validate Otp
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def validate_otp
      r = @admin_secret_obj.ga_secret_decrypted
      ga_secret_d = r.data[:plaintext]
      rotp_obj = TimeBasedOtp.new(ga_secret_d)
      r = rotp_obj.verify_with_drift_and_prior(@otp, @admin.last_otp_at)
      return error_with_identifier('invalid_api_params',
                                   'cm_uwa_vo_1',
                                   ['invalid_otp'],
                                   ''
      ) unless r.success?

      success
    end

    # Create And Update Client Whitelist Detail
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    # sets @client_whitelist_detail
    #
    def fetch_client_whitelist_detail
      @client_whitelist_detail = ClientWhitelistDetail.get_from_memcache(@client_id)
    end

    # Set Whitelist Contract Address
    #
    # * Author: Tejas
    # * Date: 27/08/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def set_whitelist_contract_address
      if @client_whitelist_detail.blank?
        create_client_whitelist_detail
      else
        update_client_whitelist_detail
      end
    end

    # Update And Fetch VOA
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    # sets @verified_operator_addresses
    #
    # @return [Result::Base]
    #
    def fetch_voa
      VerifiedOperatorAddress.where(client_id: nil,
                                    status: GlobalConstant::VerifiedOperatorAddress.unused_status).
          order('id desc').limit(1).
          update_all(client_id: @client_id, status: GlobalConstant::VerifiedOperatorAddress.active_status)

      @verified_operator_addresses = VerifiedOperatorAddress.where(
          client_id: @client_id, status: GlobalConstant::VerifiedOperatorAddress.active_status).last
    end

    # Create Client Whitelist Detail
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    # sets @active_client_whitelist_detail_obj
    # @return [Result::Base]
    #
    def create_client_whitelist_detail
      fetch_voa

      @active_client_whitelist_detail_obj = ClientWhitelistDetail.create!(
          client_id: @client_id, contract_address: @whitelist_contract_address,
          whitelister_address: @verified_operator_addresses.address,
          suspension_type: GlobalConstant::ClientWhitelistDetail.no_suspension_type,
          last_acted_by: @admin_id,
          status: GlobalConstant::ClientWhitelistDetail.active_status
      )

      check_unused_voa_count

      success
    end

    # Update Client Whitelist Detail
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    # sets @active_client_whitelist_detail_obj
    #
    # @return [Result::Base]
    #
    def update_client_whitelist_detail
      return error_with_identifier('invalid_api_params',
                                   'cm_uwa_ucwd_1',
                                   ['duplicate_whitelist_contract_address'],
                                   'There were some errors in address submission. Please review and resubmit'
      ) if @client_whitelist_detail.contract_address.downcase == @whitelist_contract_address.downcase

      @client_whitelist_detail.status = GlobalConstant::ClientWhitelistDetail.inactive_status
      @client_whitelist_detail.save!

      @active_client_whitelist_detail_obj = ClientWhitelistDetail.create!(
          client_id: @client_id, contract_address: @whitelist_contract_address,
          whitelister_address: @client_whitelist_detail.whitelister_address,
          balance: @client_whitelist_detail.balance,
          suspension_type: @client_whitelist_detail.suspension_type,
          last_acted_by: @admin_id,
          status: GlobalConstant::ClientWhitelistDetail.active_status
      )
      success
    end

    # Send email
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    def send_email
      admin_emails_for_notification = GlobalConstant::Admin.get_all_admin_emails_for(
          @client_id,
          GlobalConstant::Admin.contract_address_update_notification_type
      )

      admin_emails_for_notification.each do |admin_email|
        Email::HookCreator::SendTransactionalMail.new(
            client_id: Client::OST_KYC_CLIENT_IDENTIFIER,
            email: admin_email,
            template_name: GlobalConstant::PepoCampaigns.contract_address_update_template,
            template_vars: {client_name: @client.name, contract_type: 'Whitelist'}
        ).perform

      end
    end

    # Do remaining task in sidekiq
    #
    # * Author: Tejas
    # * Date: 10/10/2018
    # * Reviewed By:
    #
    def enqueue_job_for_rewhitelist_users

      if @rewhitelist == true
        BgJob.enqueue(
            RewhitelistJob,
            {
                client_id: @client_id
            }
        )
        Rails.logger.info('---- enqueue_job RewhitelistJob done')
      end
    end

    # Check Unused VOA Count
    #
    # * Author: Tejas
    # * Date: 10/10/2018
    # * Reviewed By:
    #
    def check_unused_voa_count
      unused_voa_count = VerifiedOperatorAddress.where(status: GlobalConstant::VerifiedOperatorAddress.unused_status).count
      # Send internal email in case of unused count is less than 10
      if unused_voa_count <= VerifiedOperatorAddress::MINIMUM_UNUSED_VOA_COUNT
        ApplicationMailer.notify(
            to: GlobalConstant::Email.default_to,
            body: "There is less than 10 voa addressses available in VerifedOperatorAddress Table.
                   Please run generate_whitelister_address.rake once",
            data: {unused_voa_count: unused_voa_count},
            subject: "Attention::Less than 10 voa available in VerifedOperatorAddress"
        ).deliver
      end
    end

    # Api response data
    #
    # * Author: Tejas
    # * Date: 09/10/2018
    # * Reviewed By:
    #
    # returns [Hash] api response data
    #
    def success_response_data
      {
          whitelist_contract_address: @active_client_whitelist_detail_obj.contract_address,
          verified_operator_address: @active_client_whitelist_detail_obj.whitelister_address
      }
    end

  end
end
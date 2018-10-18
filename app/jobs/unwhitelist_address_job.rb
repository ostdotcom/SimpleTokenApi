class UnwhitelistAddressJob < ApplicationJob

  queue_as GlobalConstant::Sidekiq.queue_name :default_high_priority_queue

  include ::Util::ResultHelper

  # Perform
  #
  # * Author: Pankaj
  # * Date: 09/05/2018
  # * Reviewed By:
  #
  def perform(params)
    init_params(params)

    r = fetch_ethereum_address
    if !r.success?
      notify_errors("Ethereum address is invalid.", r)
      update_edit_kyc_request(GlobalConstant::EditKycRequest.failed_status, r.to_json)
      return
    end

    r = validate_whitelisting_process
    if !r.success?
      notify_errors(r.error_display_text)
      update_edit_kyc_request(GlobalConstant::EditKycRequest.failed_status, r.to_json)
      return
    end

    r = send_unwhitelist_request
    if !r.success?
      notify_errors("Failed while sending unwhitelist request.", r)
      update_edit_kyc_request(GlobalConstant::EditKycRequest.failed_status, r.to_json)
      return
    end

    # Mark Edit Kyc Request as unWhitelist in process
    update_edit_kyc_request(GlobalConstant::EditKycRequest.unwhitelist_in_process_status)

    RecordEventJob.perform_now(@event)
  end

  private

  # Init Params
  #
  # * Author: Pankaj
  # * Date: 09/05/2018
  # * Reviewed By:
  #
  def init_params(params)
    @edit_kyc_id = params[:edit_kyc_id]

    @user_extended_detail_id = params[:user_extended_detail_id]

    @client_id = params[:client_id]

    @user_kyc_detail_id = params[:user_kyc_detail_id]

    @admin_email = params[:admin_email]

    @user_id = params[:user_id]

    @event = params[:event]
  end

  # Fetch Ethereum Address to unwhitelist
  #
  # * Author: Pankaj
  # * Date: 09/05/2018
  # * Reviewed By:
  #
  # Sets @ethereum_address
  #
  def fetch_ethereum_address
    user_extended_detail = UserExtendedDetail.where(id: @user_extended_detail_id).first

    r = Aws::Kms.new('kyc', 'admin').decrypt(user_extended_detail.kyc_salt)

    unless r.success?
      return error_with_data(
          'am_k_c_caaoc_6',
          'Error decrypting Kyc salt!',
          'Error decrypting Kyc salt!',
          GlobalConstant::ErrorAction.default,
          {}
      )
    end

    kyc_salt_d = r.data[:plaintext]

    r = LocalCipher.new(kyc_salt_d).decrypt(user_extended_detail.ethereum_address)
    return r unless r.success?

    @ethereum_address = r.data[:plaintext]

    success
  end

  # Make UnWhitelist API call
  #
  # * Author: Pankaj
  # * Date: 07/05/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  # Sets @kyc_whitelist_log
  #
  def send_unwhitelist_request

    Rails.logger.info("user_kyc_detail id:: #{@user_kyc_detail_id} - making private ops api call")
    r = OpsApi::Request::Whitelist.new.whitelist({
                                                     whitelister_address: api_data[:client_whitelist_detail_obj].whitelister_address,
                                                     contract_address: api_data[:client_whitelist_detail_obj].contract_address,
                                                     address: api_data[:address],
                                                     phase: api_data[:phase],
                                                     gasPrice: EstimatedGasPrice::CurrentPrice.new.fetch
                                                 })
    Rails.logger.info("Whitelist API Response: #{r.inspect}")

    unless r.success?
      get_client_whitelist_detail_obj.mark_client_eth_balance_low if GlobalConstant::ClientWhitelistDetail.low_balance_error?(r.error)
      return r
    end

    @kyc_whitelist_log = KycWhitelistLog.create!({
                                                     client_id: @client_id,
                                                     ethereum_address: api_data[:address],
                                                     client_whitelist_detail_id: api_data[:client_whitelist_detail_obj].id,
                                                     phase: api_data[:phase],
                                                     transaction_hash: r.data[:transaction_hash],
                                                     nonce: r.data[:nonce],
                                                     gas_price: r.data[:gas_price],
                                                     next_timestamp: Time.now.to_i + GlobalConstant::KycWhitelistLog.expected_transaction_mine_time,
                                                     status: GlobalConstant::KycWhitelistLog.pending_status,
                                                     failed_reason: 0
                                                 })

    success
  end

  # Validate All whitelisting checks before putting unwhitelisting request
  #
  # * Author: Pankaj
  # * Date: 07/05/2018
  # * Reviewed By:
  #
  # @return [Result::Base]
  #
  def validate_whitelisting_process
    return error_with_data(
        'uaj_2',
        "Client Whitelisting information is inactivated. Please contact Ost team.",
        "Client Whitelisting information is inactivated. Please contact Ost team.",
        GlobalConstant::ErrorAction.default,
        {}
    ) if get_client_whitelist_detail_obj.nil?

    # Check if client whitelisting is running or not
    unless get_client_whitelist_detail_obj.no_suspension_type?
      error_msg = "Whitelisting or unWhitelisting is not happening at the moment. "
      error_msg += "Whitelister eth balance is low." if get_client_whitelist_detail_obj.low_balance_suspension_type?

      return error_with_data(
          'uaj_3',
          "#{error_msg} Please try after sometime.",
          "#{error_msg} Please try after sometime.",
          GlobalConstant::ErrorAction.default,
          {}
      )
    end

    # todo: This validation has also been done before enqueue.
    KycWhitelistLog.where(client_id: @client_id, ethereum_address: @ethereum_address).all.each do |kwl|

      if (GlobalConstant::KycWhitelistLog.kyc_whitelist_confirmation_pending_statuses.include?(kwl.status))
        return error_with_data(
            'uaj_1',
            "Waiting for KYC Whitelist Confirmation. Please try after sometime!",
            "Waiting for KYC Whitelist Confirmation. Please try after sometime!",
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

    end

    success
  end

  # API Data for phase 0
  #
  # * Author: Pankaj
  # * Date: 07/05/2018
  # * Reviewed By:
  #
  # @return [Hash]
  #
  def api_data
    @api_data ||= {
        address: @ethereum_address,
        phase: 0,
        client_whitelist_detail_obj: get_client_whitelist_detail_obj
    }
  end

  # Get client_whitelist_detail obj
  #
  # * Author: Pankaj
  # * Date: 07/05/2018
  # * Reviewed By:
  #
  # @return [Ar] ClientWhitelistDetail obj
  #
  def get_client_whitelist_detail_obj
    @cwd_obj ||= ClientWhitelistDetail.where(client_id: @client_id,
                                status: GlobalConstant::ClientWhitelistDetail.active_status).first
  end

  # Update Edit Kyc requests entry with passed status
  #
  # * Author: Pankaj
  # * Date: 07/05/2018
  # * Reviewed By:
  #
  # @status [Integer] status (mandatory) - Status to be set for Edit kyc entry
  #
  def update_edit_kyc_request(status, debug_data = nil)
    EditKycRequests.where(id: @edit_kyc_id).update_all(status: status, debug_data: debug_data)
  end

  # Notify admin and internal devs about the error
  #
  # * Author: Pankaj
  # * Date: 09/05/2018
  # * Reviewed By:
  #
  def notify_errors(error_message, result_base = nil)
    user_email = User.get_from_memcache(@user_id).email

    Email::HookCreator::SendTransactionalMail.new(
        client_id: Client::OST_KYC_CLIENT_IDENTIFIER,
        email: @admin_email,
        template_name: GlobalConstant::PepoCampaigns.open_case_request_outcome_template,
        template_vars: {success: 0, email: user_email, reason_failure: error_message}
    ).perform

    # Send internal email in case of failure
    if result_base.present?
      ApplicationMailer.notify(
          to: GlobalConstant::Email.default_to,
          body: error_message + result_base.inspect,
          data: {case_id: @user_kyc_detail_id, edit_kyc_table_id: @edit_kyc_id},
          subject: "Exception::Something went wrong while Unwhitelist Edit KYC request."
      ).deliver
    end
  end

end

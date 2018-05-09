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
      notify_errors("Ethereum address is invalid.")
      update_edit_kyc_request(GlobalConstant::UserKycDetail.failed_edit_kyc)
      return
    end

    r = send_unwhitelist_request
    if !r.success?
      notify_errors("Failed while sending unwhitelist request: #{r.inspect}")
      update_edit_kyc_request(GlobalConstant::UserKycDetail.failed_edit_kyc)
      return
    end

    # Mark Edit Kyc Request as unWhitelist in process
    update_edit_kyc_request(GlobalConstant::UserKycDetail.unwhitelist_in_process_edit_kyc, {kyc_whitelist_log: @kyc_whitelist_log.id})

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
  # * Reviewed By: Sunil
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
                                                     phase: api_data[:phase]
                                                 })
    Rails.logger.info("Whitelist API Response: #{r.inspect}")
    return r unless r.success?

    @kyc_whitelist_log = KycWhitelistLog.create!({
                                                     client_id: @client_id,
                                                     ethereum_address: api_data[:address],
                                                     phase: api_data[:phase],
                                                     transaction_hash: r.data[:transaction_hash],
                                                     status: GlobalConstant::KycWhitelistLog.pending_status,
                                                     is_attention_needed: 0
                                                 })

    # TODO:: Confirm whether started unwhitelist status is actually required.
    UserKycDetail.where(id: @user_kyc_detail_id).update_all(whitelist_status: GlobalConstant::UserKycDetail.started_unwhitelist_status)

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
    ClientWhitelistDetail.where(client_id: @client_id,
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
  def notify_errors(error_message = nil)
    user_email = User.get_from_memcache(@user_id).email

    Email::HookCreator::SendTransactionalMail.new(
              client_id: Client::OST_KYC_CLIENT_IDENTIFIER,
              email: @admin_email,
              template_name: GlobalConstant::PepoCampaigns.open_case_request_outcome_template,
              template_vars: {success: false, email: user_email, reason_failure: error_message, ethereum_address_updated: false}
          ).perform

    # Send internal email in case of failure
    ApplicationMailer.notify(
        to: GlobalConstant::Email.default_to,
        body: error_message,
        data: {case_id: @user_kyc_detail_id, edit_kyc_table_id: @edit_kyc_id},
        subject: "Exception::Something went wrong while Unwhitelist Edit KYC request."
    ).deliver
  end

end

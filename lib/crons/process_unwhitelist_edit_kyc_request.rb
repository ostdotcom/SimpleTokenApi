module Crons

  class ProcessUnwhitelistEditKycRequest

    include Util::ResultHelper

    # Initialize
    #
    # * Author: Pankaj
    # * Date: 07/05/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def initialize(params)
      @wait_time = 7 # 7 Minutes
      @edit_kyc_rows = []
      @kyc_whitelist_logs = {}
      @case_ids = []
      @user_kyc_details = {}
      @user_extended_details = {}
      @admins = {}
      @users = {}
      @client_whitelist_details = {}
    end

    # Perform
    #
    # * Author: Pankaj
    # * Date: 07/05/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def perform
      fetch_unwhitelist_inprocess_edit_requests

      # No open Edit kyc requests present
      return if @edit_kyc_rows.blank?

      verify_and_open_cases

    end

    private

    # Fetch All pending unwhitelist edit kyc rows
    #
    # * Author: Pankaj
    # * Date: 07/05/2018
    # * Reviewed By:
    #
    #
    def fetch_unwhitelist_inprocess_edit_requests
      edit_kyc_requests = EditKycRequests.where(status: GlobalConstant::EditKycRequest.unwhitelist_in_process_status).limit(1000)

      admin_ids, user_ids, user_extended_detail_ids, kyc_logs, client_ids = [], [], [], [], []
      edit_kyc_requests.each do |e_k_r|
        next if e_k_r.created_at.to_i > Time.now.to_i - @wait_time.minutes.to_i
        @edit_kyc_rows << e_k_r

        @case_ids << e_k_r.case_id
        admin_ids << e_k_r.admin_id
        user_ids << e_k_r.user_id
        kyc_logs << e_k_r.debug_data[:kyc_whitelist_log].to_i
      end

      if @edit_kyc_rows.present?
        UserKycDetail.where(id: @case_ids).each do |u_k_d|
          user_extended_detail_ids << u_k_d.user_extended_detail_id
          @user_kyc_details[u_k_d.id] = u_k_d
          client_ids << u_k_d.client_id
        end

        @admins = Admin.where(id: admin_ids).index_by(&:id)
        @users = User.where(id: user_ids).index_by(&:id)
        @user_extended_details = UserExtendedDetail.where(id: user_extended_detail_ids).select("id, kyc_salt").index_by(&:id)
        @kyc_whitelist_logs = KycWhitelistLog.where(id: kyc_logs).index_by(&:id)
        @client_whitelist_details = ClientWhitelistDetail.where(client_id: client_ids,
                                  status: GlobalConstant::ClientWhitelistDetail.active_status).index_by(&:client_id)
      end

    end

    # Open Cases whose unwhitelisting is completed
    #
    # * Author: Pankaj
    # * Date: 07/05/2018
    # * Reviewed By:
    #
    #
    def verify_and_open_cases
      @edit_kyc_rows.each do |ekr|
        kyc_log_id = ekr.debug_data[:kyc_whitelist_log].to_i

        user_kyc_detail = @user_kyc_details[ekr.case_id]
        client_id = user_kyc_detail.client_id

        r = verify_if_un_whitelisted(kyc_log_id, client_id)

        if r.success?
          # Update USer kyc detail
          user_kyc_detail.admin_status = GlobalConstant::UserKycDetail.unprocessed_admin_status
          user_kyc_detail.whitelist_status = GlobalConstant::UserKycDetail.unprocessed_whitelist_status

          # todo: record timestamps?? wont affect much
          user_kyc_detail.last_acted_by = @admin_id
          user_kyc_detail.last_acted_timestamp = Time.now.to_i

          user_kyc_detail.save!

          update_edit_kyc_row(ekr, GlobalConstant::EditKycRequest.processed_status)

          log_activity(ekr)

          send_email(true, ekr)
        else
          update_edit_kyc_row(ekr, GlobalConstant::EditKycRequest.failed_status)
          send_email(false, ekr, r.error_display_text)
        end
      end
    end

    # Check if user is un_whitelisted
    #
    # * Author: Pankaj
    # * Date: 07/05/2018
    # * Reviewed By:
    #
    # @return [Result::Base]
    #
    def verify_if_un_whitelisted(kyc_log_id, client_id)

      kwl = @kyc_whitelist_logs[kyc_log_id]

      # todo: wait and check for confirmed_status so that confirm cron is not affected.. change.. or just check the transaction hash status??

      if kwl.blank? || kwl.status != GlobalConstant::KycWhitelistLog.confirmed_status ||
          kwl.is_attention_needed != GlobalConstant::KycWhitelistLog.attention_not_needed

        return error_with_data(
            'cr_puekr_1',
            "KycWhitelistLog: #{kyc_log_id} is still not confirmed or it's marked is_attention_needed!",
            "KycWhitelistLog: #{kyc_log_id} is still not confirmed or it's marked is_attention_needed!",
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

      return error_with_data(
          'cr_puekr_2',
          "Whitelist Detail not found for client #{client_id}. KYC Log: #{kyc_log_id}",
          "Whitelist Detail not found for client #{client_id}. KYC Log: #{kyc_log_id}",
          GlobalConstant::ErrorAction.default,
          {}
      ) if @client_whitelist_details[client_id].nil?

      r = OpsApi::Request::GetWhitelistStatus.new.perform(contract_address: @client_whitelist_details[client_id].contract_address,
                                                          ethereum_address: kwl.ethereum_address)
      return r unless r.success?

      _phase = r.data['phase']

      if !Util::CommonValidator.is_numeric?(_phase) || r.data['phase'].to_i != 0
        return error_with_data(
            'cr_puekr_3',
            "Invalid Phase: #{_phase} for KycWhitelistLog: #{kwl.id}",
            "Invalid Phase: #{_phase} for KycWhitelistLog: #{kwl.id}",
            GlobalConstant::ErrorAction.default,
            {}
        )
      end

      success
    end

    # Log Open Case User Activity
    #
    # * Author: Pankaj
    # * Date: 07/05/2018
    # * Reviewed By:
    #
    def log_activity(edit_kyc_row)

      BgJob.enqueue(
          UserActivityLogJob,
          {
              user_id: edit_kyc_row.user_id,
              admin_id: edit_kyc_row.admin_id,
              action: GlobalConstant::UserActivityLog.open_case,
              action_timestamp: Time.now.to_i,
              extra_data: {
                  case_id: edit_kyc_row.case_id
              }
          }
      )

    end

    # Send email to admins and notify devs in case of error
    #
    # * Author: Pankaj
    # * Date: 09/05/2018
    # * Reviewed By:
    #
    def send_email(is_success, edit_kyc_row, error_message = nil)
      user_email = User.get_from_memcache(edit_kyc_row.user_id).email

      Email::HookCreator::SendTransactionalMail.new(
          client_id: Client::OST_KYC_CLIENT_IDENTIFIER,
          email: Admin.get_from_memcache(edit_kyc_row.admin_id).email,
          template_name: GlobalConstant::PepoCampaigns.open_case_request_outcome_template,
          template_vars: {success: is_success, email: user_email, reason_failure: error_message, ethereum_address_updated: false}
      ).perform

      # Send internal email in case of failure
      unless is_success
        ApplicationMailer.notify(
            to: GlobalConstant::Email.default_to,
            body: error_message,
            data: {case_id: edit_kyc_row.case_id, edit_kyc_table_id: edit_kyc_row.id},
            subject: "Exception::Something went wrong while opening case of Unwhitelisted Edit KYC request."
        ).deliver
      end
    end

    # Update Edit Kyc Request
    #
    # * Author: Pankaj
    # * Date: 09/05/2018
    # * Reviewed By:
    #
    def update_edit_kyc_row(ekr, status)
      ekr.status = status
      ekr.save
    end

  end

end
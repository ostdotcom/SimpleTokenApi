module AdminManagement

  class ProcessUnwhitelist

    include Util::ResultHelper

    # initialize
    #
    # * Author: Sachin
    # * Date: 05/06/2018
    # * Reviewed By: Aman
    #
    # @return [AdminManagement::ProcessUnwhitelist]
    #
    def initialize(params)
      @user_kyc_detail = params[:user_kyc_detail]
      @kyc_whitelist_log = params[:kyc_whitelist_log]

      @edit_kyc_request = nil
    end

    # Perform
    #
    # * Author: Sachin
    # * Date: 05/06/2018
    # * Reviewed By: Aman
    #
    def perform
      r = fetch_edit_kyc_request
      return r unless r.success?

      if confirmed_whitelist_log_status?

        reopen_case
        log_activity
        send_email(true)
        record_event_job

      elsif failed_whitelist_log_status?
        update_edit_kyc_row(GlobalConstant::EditKycRequest.failed_status)
        send_email(false)
      else
        fail("user_kyc_whitelist_log - #{@kyc_whitelist_log.id} - Unreachable Code")
      end
    end

    private


    # fetch edit_kyc_request row
    #
    # * Author: Sachin
    # * Date: 05/06/2018
    # * Reviewed By: Aman
    #
    # Sets @edit_kyc_request
    #
    # return [Result::Base]
    #
    def fetch_edit_kyc_request
      edit_kyc_requests = EditKycRequests.where(case_id: @user_kyc_detail.id,
                                                status: GlobalConstant::EditKycRequest.unwhitelist_in_process_status).all


      if edit_kyc_requests.length != 1
        notify_devs(
            {kyc_whitelist_log_id: @kyc_whitelist_log.id, edit_kyc_requests: edit_kyc_requests},
            "Error in getting Edit kyc request row"
        )

        return error_with_data(
            'am_pu_b_fekr_1',
            'Error in getting Edit kyc request row',
            'Error in getting Edit kyc request row',
            GlobalConstant::ErrorAction.default,
            {}
        )
      end


      @edit_kyc_request = edit_kyc_requests[0]

      success
    end

    # is confirmed status
    #
    # * Author: Sachin
    # * Date: 05/06/2018
    # * Reviewed By: Aman
    #
    # @return [Boolean]
    #
    def confirmed_whitelist_log_status?
      GlobalConstant::KycWhitelistLog.confirmed_status == @kyc_whitelist_log.status
    end

    # is confirmed status
    #
    # * Author: Sachin
    # * Date: 05/06/2018
    # * Reviewed By: Aman
    #
    # @return [Boolean]
    #
    def failed_whitelist_log_status?
      GlobalConstant::KycWhitelistLog.failed_status == @kyc_whitelist_log.status ||
          @kyc_whitelist_log.failed_reason != GlobalConstant::KycWhitelistLog.not_failed
    end

    # reopen the case for user
    #
    # * Author: Sachin
    # * Date: 05/06/2018
    # * Reviewed By: Aman
    #
    # @return [Boolean]
    #
    def reopen_case
      # Update USer kyc detail
      @user_kyc_detail.admin_status = GlobalConstant::UserKycDetail.unprocessed_admin_status
      @user_kyc_detail.aml_status = GlobalConstant::UserKycDetail.pending_aml_status  if @user_kyc_detail.aml_status != GlobalConstant::UserKycDetail.unprocessed_aml_status
      @user_kyc_detail.aml_user_id = nil
      @user_kyc_detail.whitelist_status = GlobalConstant::UserKycDetail.unprocessed_whitelist_status
      @user_kyc_detail.kyc_confirmed_at = nil
      @user_kyc_detail.last_acted_by = @edit_kyc_request.admin_id
      @user_kyc_detail.last_acted_timestamp = Time.now.to_i
      @user_kyc_detail.last_reopened_at = Time.now.to_i
      @user_kyc_detail.save!

      update_edit_kyc_row(GlobalConstant::EditKycRequest.processed_status)
    end

    # Log Open Case User Activity
    #
    # * Author: Pankaj
    # * Date: 07/05/2018
    # * Reviewed By:
    #
    def log_activity

      BgJob.enqueue(
          UserActivityLogJob,
          {
              user_id: @edit_kyc_request.user_id,
              admin_id: @edit_kyc_request.admin_id,
              action: GlobalConstant::UserActivityLog.open_case,
              action_timestamp: Time.now.to_i,
              extra_data: {
                  case_id: @edit_kyc_request.case_id
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
    def send_email(is_success)
      user_email = User.get_from_memcache(@edit_kyc_request.user_id).email

      Email::HookCreator::SendTransactionalMail.new(
          client_id: Client::OST_KYC_CLIENT_IDENTIFIER,
          email: Admin.get_from_memcache(@edit_kyc_request.admin_id).email,
          template_name: GlobalConstant::PepoCampaigns.open_case_request_outcome_template,
          template_vars: {success: is_success.to_i, email: user_email, reason_failure: "UnWhitelist Transaction has failed"}
      ).perform

      # Send internal email in case of failure
      unless is_success
        ApplicationMailer.notify(
            to: GlobalConstant::Email.default_to,
            body: "UnWhitelist Transaction has failed",
            data: {case_id: @edit_kyc_request.case_id, edit_kyc_table_id: @edit_kyc_request.id},
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
    def update_edit_kyc_row(status)
      @edit_kyc_request.status = status
      @edit_kyc_request.save!
    end


    # notify devs if required
    #
    # * Author: Aman
    # * Date: 25/10/2017
    # * Reviewed By: Sunil
    #
    def notify_devs(error_data, err_message)
      ApplicationMailer.notify(
          body: {err_message: err_message},
          data: {
              error_data: error_data
          },
          subject: 'Error while ProcessUnwhitelist'
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
                                     event_source: GlobalConstant::Event.web_source,
                                     event_name: GlobalConstant::Event.kyc_reopen_name,
                                     event_data: {
                                         user_kyc_detail: @user_kyc_detail.get_hash,
                                         admin: @user_kyc_detail.get_last_acted_admin_hash
                                     },
                                     event_timestamp: Time.now.to_i
                                 })

    end



  end

end
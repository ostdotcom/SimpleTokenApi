module AdminManagement
module Kyc
  module Aml
    class Base < ServicesBase

      def initialize(params)
        super

        @admin_id = @params[:admin_id]
        @client_id = @params[:client_id]
        @case_id = @params[:id]
        @api_response_data = {}

        @extra_data = {}

        @user_kyc_detail = nil

      end

      def validate_and_sanitize
        r = validate
        return r unless r.success?

        r = fetch_and_validate_client
        return r unless r.success?

        r = fetch_and_validate_admin
        return r unless r.success?

        @user_kyc_detail = UserKycDetail.where(client_id: @client_id, id: @case_id).first

        return error_with_data(
            'ka_b_vs_1',
            'KYC not found',
            'KYC not found',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @user_kyc_detail.blank? || @user_kyc_detail.inactive_status?

        return error_with_data(
            'ka_b_vs_4',
            'Closed case can not be changed.',
            'Closed case can not be changed.',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @user_kyc_detail.case_closed?

        success
      end


      def is_duplicate_user?
        if UserExtendedDetail.is_duplicate_kyc_approved_user?(@user_kyc_detail.client_id,
                                                           @user_kyc_detail.user_extended_detail_id)
          return error_with_data(
             GlobalConstant::KycAutoApproveFailedReason.duplicate_kyc,
            'Duplicate Kyc User for approval.',
            'Duplicate Kyc User for approval.',
            GlobalConstant::ErrorAction.default,
            {}
          )
      end
      success
      end


      def aml_search
        @aml_search ||= AmlSearch.where(user_kyc_detail_id: @user_kyc_detail.id,
                                        user_extended_detail_id: @user_kyc_detail.user_extended_detail_id).first
      end

      def aml_matches
        @aml_matches ||= AmlMatch.where(aml_search_uuid: aml_search.uuid).all
      end

      def send_approved_email
        return if !@client.is_email_setup_done? || @client.is_whitelist_setup_done? ||
            @client.is_st_token_sale_client? || ! @client.client_kyc_config_detail.auto_send_kyc_approve_email?

        @user = User.where(client_id: @client_id, id: @user_kyc_detail.user_id).first

        if @user_kyc_detail.kyc_approved?
          Email::HookCreator::SendTransactionalMail.new(
              client_id: @client.id,
              email: @user.email,
              template_name: GlobalConstant::PepoCampaigns.kyc_approved_template,
              template_vars: GlobalConstant::PepoCampaigns.kyc_approve_default_template_vars(@client_id)
          ).perform
        end

      end


      def update_aml_match_status

        unprocessed_matches = aml_matches.map(&:qr_code) - (@matched_ids + @unmatched_ids)

        aml_matches.where(qr_code: @matched_ids).update_all(status: GlobalConstant::AmlMatch.match_status) if @matched_ids.present?

        aml_matches.where(qr_code: @unmatched_ids).update_all(status: GlobalConstant::AmlMatch.no_match_status) if @unmatched_ids.present?

        aml_matches.where(qr_code: unprocessed_matches).update_all(status: GlobalConstant::AmlMatch.unprocessed_status) if unprocessed_matches.present?

      end


      def validate_matched_unmatched_records

        r = check_if_common_matched_unmatched_records
        return r unless r.success?

        r = validate_matched_unmatched_ids
        return r unless r.success?

        success

      end

      def validate_matched_unmatched_ids
        return error_with_data(
            'ka_b_vmi_1',
            'incorrect matched ids',
            'incorrect matched ids',
            GlobalConstant::ErrorAction.default,
            {}
        ) if ((@matched_ids + @unmatched_ids) - aml_matches.map(&:qr_code)).present?
        success
      end

      def check_if_common_matched_unmatched_records
        return error_with_data(
            'ka_ad_vm_1',
            'match record can not be matched and unmatched together',
            'match record can not be matched and unmatched together',
            GlobalConstant::ErrorAction.default,
            {}
        ) if  (@matched_ids & @unmatched_ids).present?
        success
      end

      def enqueue_job(event_src)
        BgJob.enqueue(
            WebhookJob::RecordEvent,
            {
                client_id: @user_kyc_detail.client_id,
                event_source: event_src,
                event_name: GlobalConstant::Event.kyc_status_update_name,
                event_data: {
                    user_kyc_detail: @user_kyc_detail.get_hash,
                    admin: @admin.get_hash
                },
                event_timestamp: Time.now.to_i
            }
        )

      end

      def log_admin_action
        BgJob.enqueue(
            UserActivityLogJob,
            {
                user_id: @user_kyc_detail.user_id,
                case_id: @case_id,
                admin_id: @admin_id,
                action: logging_action_type,
                action_timestamp: Time.now.to_i,
                extra_data: @extra_data
            }
        )
      end

      def get_event_source
        is_auto_approve_admin? ? GlobalConstant::Event.kyc_system_source : GlobalConstant::Event.web_source
      end

      def is_aml_auto_approved?
        aml_matches.blank? && aml_search.status == GlobalConstant::AmlSearch.processed_status
      end

      def is_auto_approve_admin?
        @is_auto_approve && (@admin_id == Admin::AUTO_APPROVE_ADMIN_ID)
      end





    end
  end
end
end
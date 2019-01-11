module AdminManagement
module Kyc
  module Aml
    class DenyCase < Base

      def initialize(params)
        super

        @matched_ids = params[:matched_ids]
        @unmatched_ids = params[:unmatched_ids]

      end

      def perform
        r = validate_and_sanitize
        return r unless r.success?

        update_user_kyc_status

        update_aml_match_status

        remove_reserved_branded_token

        log_admin_action

        send_denied_email

        success_with_data(@api_response_data)

      end

      def validate_and_sanitize
        r = super
        return r unless r.success?

        r = validate_matches
        return r unless r.success?

        success
      end

      def update_user_kyc_status
        @user_kyc_detail.admin_status = GlobalConstant::UserKycDetail.denied_admin_status
        @user_kyc_detail.last_acted_by = @admin_id
        @user_kyc_detail.last_acted_timestamp = Time.now.to_i
        @user_kyc_detail.admin_action_types = 0
        if @user_kyc_detail.changed?
          @user_kyc_detail.save!
          enqueue_job(GlobalConstant::Event.web_source)
        end

      end

      def remove_reserved_branded_token
        return unless @user_kyc_detail.kyc_denied?
        return unless @client.is_st_token_sale_client?

        @user.bt_name = nil
        @user.save! if @user.changed?
      end



      def validate_matches

        return success unless (@matched_ids.present? || @unmatched_ids.present?)

        # common ids in matches_ids and unmatched_ids
        r = validate_matched_unmatched_records
        return r unless r.success?

        return success if @matched_ids.present?

        r = validate_unmatched_ids
        return r unless r.success?

        success

      end

      def logging_action_type
        GlobalConstant::UserActivityLog.kyc_denied_action
      end

        # Send email
        #
        # * Author: Mayur
        # * Date: 10/1/2019
        # * Reviewed By:
        #
        def send_denied_email
          return if (!@client.is_email_setup_done?) || (!@client.client_kyc_config_detail.auto_send_kyc_deny_email?)
          if @user_kyc_detail.kyc_denied?
            Email::HookCreator::SendTransactionalMail.new(
                client_id: @client.id,
                email: @user.email,
                template_name: GlobalConstant::PepoCampaigns.kyc_denied_template,
                template_vars: {}
            ).perform
          end


      end

    end
  end
end
end
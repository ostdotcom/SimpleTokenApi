module AdminManagement

  module Kyc

    module AdminAction

      class DenyKyc < AdminManagement::Kyc::AdminAction::Base

        # Initialize
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By: Sunil
        #
        # @params [Integer] admin_id (mandatory) - logged in admin
        # @params [Integer] client_id (mandatory) - logged in admin's client id
        # @params [Integer] id (mandatory)
        #
        # @return [AdminManagement::Kyc::AdminAction::DenyKyc]
        #
        def initialize(params)
          super
        end

        # Deny KYC by admin
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By: Sunil
        #
        # return [Result::Base]
        #
        def perform

          r = validate_and_sanitize
          return r unless r.success?

          update_user_kyc_status

          remove_reserved_branded_token

          log_admin_action

          send_email

          enqueue_job

          success_with_data(@api_response_data)
        end

        private

        # Validate & sanitize
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By: Sunil
        #
        # return [Result::Base]
        #
        def validate_and_sanitize
          super
        end

        # Change case's admin status
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By: Sunil
        #
        def update_user_kyc_status
          @user_kyc_detail.admin_status = GlobalConstant::UserKycDetail.denied_admin_status
          @user_kyc_detail.last_acted_by = @admin_id
          @user_kyc_detail.last_acted_timestamp = Time.now.to_i
          @user_kyc_detail.admin_action_types = 0
          @user_kyc_detail.save! if @user_kyc_detail.changed?
        end

        # remove branded token reserved for user
        #
        # * Author: Aman
        # * Date: 01/11/2017
        # * Reviewed By:
        #
        def remove_reserved_branded_token
          return unless @user_kyc_detail.kyc_denied?
          return unless @client.is_st_token_sale_client?

          @user.bt_name = nil
          @user.save! if @user.changed?
        end

        # Send email
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By: Sunil
        #
        def send_email
          return unless @client.is_email_setup_done?

          if @user_kyc_detail.kyc_denied?
            Email::HookCreator::SendTransactionalMail.new(
                client_id: @client.id,
                email: @user.email,
                template_name: GlobalConstant::PepoCampaigns.kyc_denied_template,
                template_vars: {}
            ).perform
          end
        end

        # user action log table action name
        #
        # * Author: Aman
        # * Date: 21/10/2017
        # * Reviewed By: Sunil
        #
        def logging_action_type
          GlobalConstant::UserActivityLog.kyc_denied_action
        end

        # Do remaining task in sidekiq
        #
        # * Author: Tejas
        # * Date: 16/10/2018
        # * Reviewed By:
        #
        def enqueue_job
          BgJob.enqueue(
              WebhookJob::RecordEvent,
              {
                  client_id: @user_kyc_detail.client_id,
                  event_source: GlobalConstant::Event.web_source,
                  event_name: GlobalConstant::Event.kyc_status_update_name,
                  event_data: {
                      user_kyc_detail: @user_kyc_detail.get_hash,
                      admin: @admin.get_hash
                  },
                  event_timestamp: Time.now.to_i
              }
          )

        end

      end

    end

  end

end

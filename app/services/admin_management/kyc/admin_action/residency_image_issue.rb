module AdminManagement

  module Kyc

    module AdminAction

      class ResidencyImageIssue < AdminManagement::Kyc::AdminAction::Base

        # Deny KYC by admin
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By: Sunil
        #
        # @params [Integer] admin_id (mandatory) - logged in admin
        # @params [Integer] client_id (mandatory) - logged in admin's client id
        # @params [Integer] case_id (mandatory)
        #
        # @return [AdminManagement::Kyc::AdminAction::ResidencyImageIssue]
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

          r = validate_for_email_setup
          return r unless r.success?

          log_admin_action

          send_email

          update_kyc_details

          success_with_data(@api_response_data)
        end

        private

        # Send email
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By: Sunil
        #
        def send_email

          Email::HookCreator::SendTransactionalMail.new(
              email: @user.email,
              template_name: GlobalConstant::PepoCampaigns.kyc_residency_image_issue_template,
              template_vars: @email_temp_vars
          ).perform

        end

        # Update Kyc Details
        #
        # * Author: Aman
        # * Date: 25/10/2017
        # * Reviewed By:
        #
        def update_kyc_details
          @user_kyc_detail.admin_action_type = GlobalConstant::UserKycDetail.residency_issue_admin_action_type
          @user_kyc_detail.last_acted_by  = @admin_id
          @user_kyc_detail.save! if @user_kyc_detail.changed?
        end

        # user action log table action name
        #
        # * Author: Aman
        # * Date: 21/10/2017
        # * Reviewed By: Sunil
        #
        def logging_action_type
          GlobalConstant::UserActivityLog.residency_issue_email_sent_action
        end

      end

    end

  end

end

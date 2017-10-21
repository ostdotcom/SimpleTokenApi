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

          log_admin_action

          send_email

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
              template_vars: {}
          ).perform

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

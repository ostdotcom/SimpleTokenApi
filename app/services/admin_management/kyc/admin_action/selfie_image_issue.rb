module AdminManagement

  module Kyc

    module AdminAction

      class SelfieImageIssue < AdminManagement::Kyc::AdminAction::Base

        # Deny KYC by admin
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By:
        #
        # @param [Integer] admin_id (mandatory) - logged in admin
        #
        def initialize(params)
          super

          @admin_id = @params[:admin_id]
          @api_response_data = {}
        end

        # Deny KYC by admin
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By:
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
        # * Reviewed By:
        #
        def send_email

          Email::HookCreator::SendTransactionalMail.new(
              email: @user.email,
              template_name: GlobalConstant::PepoCampaigns.kyc_selfie_image_issue_template,
              template_vars: {}
          ).perform

        end

      end

    end

  end

end

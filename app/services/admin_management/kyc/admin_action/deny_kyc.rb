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
        # @params [Integer] case_id (mandatory)
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
          @user_kyc_detail.save!
        end

        # remove branded token reserved for user
        #
        # * Author: Aman
        # * Date: 01/11/2017
        # * Reviewed By:
        #
        def remove_reserved_branded_token
          return unless @user_kyc_detail.kyc_denied?

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
          if @user_kyc_detail.kyc_denied?
            Email::HookCreator::SendTransactionalMail.new(
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

      end

    end

  end

end

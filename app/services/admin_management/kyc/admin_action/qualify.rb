module AdminManagement

  module Kyc

    module AdminAction

      class Qualify < AdminManagement::Kyc::AdminAction::Base

        # Initialize
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By:
        #
        # @param [Integer] admin_id (mandatory) - logged in admin
        # @param [Integer] case_id (mandatory)
        #
        # @return [AdminManagement::Kyc::CheckDetails]
        #
        def initialize(params)
          super
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

          update_user_kyc_status

          log_admin_action

          success_with_data(@api_response_data)
        end

        private

        # Validate & sanitize
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By:
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
        # * Reviewed By:
        #
        def update_user_kyc_status
          @user_kyc_detail.admin_status = GlobalConstant::UserKycDetail.qualified_admin_status
          @user_kyc_detail.save!
        end

        # log admin action
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By:
        #
        def log_admin_action

        end

        # Send email
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By:
        #
        def send_email

          if @user_kyc_detail.kyc_approved?
            Email::HookCreator::SendTransactionalMail.new(
                email: @user.email,
                template_name: GlobalConstant::PepoCampaigns.kyc_approved_template,
                template_vars: {
                    token_sale_participation_phase: @user_kyc_detail.token_sale_participation_phase,
                    is_sale_active: (Time.now >= GlobalConstant::TokenSale.public_sale_start_date)
                }
            ).perform
          end

        end

      end

    end

  end

end

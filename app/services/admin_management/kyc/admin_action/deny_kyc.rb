module AdminManagement

  module Kyc

    module AdminAction

      class DenyKyc < AdminManagement::Kyc::AdminAction::Base

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

          enqueue_job

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
          UserKycDetail.where(id: @case_id).update_all(admin_status: GlobalConstant::UserKycDetail.denied_admin_status)
        end

        # log admin action
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By:
        #
        def log_admin_action

        end

        # log admin action
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By:
        #
        def enqueue_job
          # check and send email in async
        end

      end

    end

  end

end

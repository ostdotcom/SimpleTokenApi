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
        # @params [Integer] admin_id (mandatory) - logged in admin
        # @params [Integer] case_id (mandatory)
        #
        # @return [AdminManagement::Kyc::AdminAction::Qualify]
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

          log_admin_action

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
          r = super
          return r unless r.success?

          return success unless is_duplicate_kyc_approved_user?

          error_with_data(
              'am_k_aa_qf_1',
              'Duplicate Kyc User for approval.',
              'Duplicate Kyc User for approval.',
              GlobalConstant::ErrorAction.default,
              {}
          )
        end

        # Check if Duplicate KYC Approved User
        #
        # * Author: Abhay
        # * Date: 30/10/2017
        # * Reviewed By:
        #
        # return [Bool] true/false
        #
        def is_duplicate_kyc_approved_user?
          other_kyc_approved_user_ids = []

          UserKycDuplicationLog.active_ethereum_duplicates.
              where("user1_id = ? OR user2_id = ?", @user_kyc_detail.user_id, @user_kyc_detail.user_id).each do |ukdl|
            other_kyc_approved_user_ids << ukdl.user1_id if ukdl.user1_id != @user_kyc_detail.user_id
            other_kyc_approved_user_ids << ukdl.user2_id if ukdl.user2_id != @user_kyc_detail.user_id
          end
          return false if other_kyc_approved_user_ids.blank?

          UserKycDetail.where(user_id: other_kyc_approved_user_ids).kyc_admin_and_cynopsis_approved.exists?
        end

        # Change case's admin status
        #
        # * Author: Alpesh
        # * Date: 15/10/2017
        # * Reviewed By: Sunil
        #
        def update_user_kyc_status
          @user_kyc_detail.admin_status = GlobalConstant::UserKycDetail.qualified_admin_status
          @user_kyc_detail.save!
        end

        # user action log table action name
        #
        # * Author: Aman
        # * Date: 21/10/2017
        # * Reviewed By: Sunil
        #
        def logging_action_type
          GlobalConstant::UserActivityLog.kyc_qualified_action
        end

      end

    end

  end

end

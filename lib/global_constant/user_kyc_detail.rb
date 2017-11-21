# frozen_string_literal: true
module GlobalConstant

  class UserKycDetail

    class << self

      ### Cynopsis Status Start ###

      def un_processed_cynopsis_status
        'un_processed_cynopsis_status'
      end

      def cleared_cynopsis_status
        'cleared_cynopsis_status'
      end

      def pending_cynopsis_status
        'pending_cynopsis_status'
      end

      def approved_cynopsis_status
        'approved_cynopsis_status'
      end

      def rejected_cynopsis_status
        'rejected_cynopsis_status'
      end

      ### Cynopsis Status End ###

      def cynopsis_approved_statuses
        [cleared_cynopsis_status, approved_cynopsis_status]
      end

      def admin_approved_statuses
        [qualified_admin_status]
      end


      ### Admin Status Start ###

      def un_processed_admin_status
        'un_processed_admin_status'
      end

      def qualified_admin_status
        'qualified_admin_status'
      end

      def denied_admin_status
        'denied_admin_status'
      end

      ### Admin Status End ###

      ### kyc_status starts###

      def kyc_approved_status
        'approved'
      end

      def kyc_denied_status
        'denied'
      end

      def kyc_pending_status
        'pending'
      end

      ### kyc_status ends###

      ### kyc duplicate state###

      def unprocessed_kyc_duplicate_status
        'unprocessed'
      end

      def never_kyc_duplicate_status
        'never'
      end

      def is_kyc_duplicate_status
        'is'
      end

      def was_kyc_duplicate_status
        'was'
      end

      ### kyc duplicate state ends###

      ### email duplicate state###

      def yes_email_duplicate_status
        'yes'
      end

      def no_email_duplicate_status
        'no'
      end

      ### email duplicate state ends###

      ### whitelist status ####

      def unprocessed_whitelist_status
        'unprocessed'
      end

      def started_whitelist_status
        'started'
      end

      def done_whitelist_status
        'done'
      end

      def failed_whitelist_status
        'failed'
      end

      ### whitelist status ####


      ### admin action type ####

      def no_admin_action_type
        'no'
      end

      def data_mismatch_admin_action_type
        'data_mismatch'
      end

      def passport_issue_admin_action_type
        'passport_issue'
      end

      def selfie_issue_admin_action_type
        'selfie_issue'
      end

      def residency_issue_admin_action_type
        'residency_issue'
      end

      ### admin action type ####

      ### Edit KYC request status start ####

      def unprocessed_edit_kyc
        'unprocessed'
      end

      def processed_edit_kyc
        'processed'
      end

      def failed_edit_kyc
        'failed'
      end

      ### Edit KYC request status end ####

      # Get mapped cynopsis status from response status of cynopsis call
      #
      # * Author: Aman
      # * Date: 24/10/2017
      # * Reviewed By: Sunil
      #
      #return[String] returns mapping of cynopsis status
      #
      def get_cynopsis_status(approval_status)

        if approval_status == 'PENDING'
          pending_cynopsis_status
        elsif approval_status == 'CLEARED'
          cleared_cynopsis_status
        elsif approval_status == 'ACCEPTED'
          approved_cynopsis_status
        elsif approval_status == 'REJECTED'
          rejected_cynopsis_status
        else
          un_processed_cynopsis_status
        end
      end


    end

  end

end

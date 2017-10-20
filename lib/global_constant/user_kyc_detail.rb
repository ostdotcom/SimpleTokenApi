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

      def whitelisted_admin_status
        'whitelisted_admin_status'
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


    end

  end

end

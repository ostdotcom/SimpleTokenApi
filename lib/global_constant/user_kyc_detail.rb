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

      ### duplicate state###

      def true_status
        'true'
      end

      def false_status
        'false'
      end

      ### duplicate state ends###


    end

  end

end

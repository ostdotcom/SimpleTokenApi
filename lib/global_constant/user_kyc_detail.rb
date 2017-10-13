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

    end

  end

end

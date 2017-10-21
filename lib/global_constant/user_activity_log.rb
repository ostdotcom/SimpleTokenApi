# frozen_string_literal: true
module GlobalConstant

  class UserActivityLog

    class << self

      ########## types ###########

      def admin_log_type
        'admin'
      end

      def developer_log_type
        'developer'
      end

      ########## types ###########

      ########## actions ###########

      def register_action
        'register'
      end

      def double_opt_in_action
        'double_opt_in'
      end

      def update_kyc_action
        'update_kyc'
      end

      def kyc_denied_action
        'kyc_denied'
      end

      def kyc_qualified_action
        'kyc_qualified'
      end

      def data_mismatch_email_sent_action
        'data_mismatch_email_sent'
      end

      def passport_issue_email_sent_action
        'passport_issue_email_sent'
      end

      def selfie_issue_email_sent_action
        'selfie_issue_email_sent'
      end

      ########## actions ###########

      def admin_actions
        [
            register_action,
            double_opt_in_action,
            update_kyc_action,
            kyc_denied_action,
            kyc_qualified_action,
            data_mismatch_email_sent_action,
            passport_issue_email_sent_action,
            selfie_issue_email_sent_action
        ]
      end

    end

  end


end

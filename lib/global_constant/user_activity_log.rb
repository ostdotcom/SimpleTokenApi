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

      def residency_issue_email_sent_action
        'residency_issue_email_sent'
      end

      ## developer use action##

      def login_action
        'login'
      end

      def kyc_whitelist_attention_needed
        'kyc_whitelist_attention_needed'
      end

      def kyc_whitelist_processor_error
        'kyc_whitelist_processor_error'
      end

      def cynopsis_api_error
        'cynopsis_api_error'
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
            selfie_issue_email_sent_action,
            residency_issue_email_sent_action,
            kyc_whitelist_attention_needed,
            kyc_whitelist_processor_error,
            cynopsis_api_error
        ]
      end

      def humanized_actions
        {
            register_action => 'User registered',
            double_opt_in_action => 'User did double opt-in',
            update_kyc_action => 'Updated KYC',
            kyc_denied_action => 'KYC denied',
            kyc_qualified_action => 'KYC approved',
            data_mismatch_email_sent_action => 'KYC data mismatch email sent',
            passport_issue_email_sent_action => 'KYC passport issue email sent',
            selfie_issue_email_sent_action => 'KYC selfie issue email sent',
            residency_issue_email_sent_action => 'KYC residency issue email sent',
        }
      end

    end

  end


end

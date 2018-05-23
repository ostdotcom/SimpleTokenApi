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

      def kyc_issue_email_sent_action
        'kyc_issue_email_sent'
      end

      def update_ethereum_address
        'update_ethereum_address'
      end

      def open_case
        'open_case'
      end

      def phase_changed_to_early_access
        'phase_changed_to_early_access'
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
            kyc_whitelist_attention_needed,
            kyc_whitelist_processor_error,
            cynopsis_api_error,
            update_ethereum_address,
            open_case,
            phase_changed_to_early_access,
            kyc_issue_email_sent_action
        ]
      end

      # def humanized_actions
      #   {
      #       register_action => 'User registered',
      #       double_opt_in_action => 'User did double opt-in',
      #       update_kyc_action => 'Updated KYC',
      #       kyc_denied_action => 'KYC denied',
      #       kyc_qualified_action => 'KYC approved',
      #
      #       #todo: WEBCODECHANGE
      #
      #       kyc_issue_email_sent_action => '',
      #
      #       # data_mismatch_email_sent_action => 'KYC data mismatch email sent',
      #       # document_id_issue_email_sent_action => 'KYC document ID issue email sent',
      #       # selfie_issue_email_sent_action => 'KYC selfie issue email sent',
      #       # residency_issue_email_sent_action => 'KYC residency issue email sent',
      #
      #       update_ethereum_address => "Ethereum Address Updated",
      #       open_case => "Case is Opened Again",
      #       phase_changed_to_early_access => "Phase Changed to Early Access"
      #   }
      # end

      # hash of all categories and subcategories for kyc issue email sent log
      # other_issue_admin_action_type - is a text string instead of enum

      def kyc_issue_email_sent_action_categories
        {"#{GlobalConstant::UserKycDetail.data_mismatch_admin_action_type}" => {
            "first_name" => {display_text: 'First Name'},
            "last_name" => {display_text: 'Last Name'},
            "birthdate" => {display_text: 'Birthdate'},
            "nationality" => {display_text: 'Nationality'},
            "document_id_number" => {display_text: 'Document id number'}
        },
         "#{GlobalConstant::UserKycDetail.document_issue_admin_action_type}" => {
             "document_id_issue" => {display_text: 'Document Id issue'},
             "selfie_issue" => {display_text: 'Selfie issue'},
             "residency_proof_issue" => {display_text: 'Residency Image Issue'},
             "investor_proof_issue" => {display_text: 'Investor proof issue'}
         },
         "#{GlobalConstant::UserKycDetail.other_issue_admin_action_type}" => ''
        }
      end

    end

  end


end

# frozen_string_literal: true
module GlobalConstant

  class Admin
    # GlobalConstant::Admin

    class << self

      ### Status Start ###

      def active_status
        'active'
      end

      def invited_status
        'invited'
      end

      def deleted_status
        'deleted'
      end

      ### Status End ###

      ### Role Start ###

      def normal_admin_role
        'normal_admin'
      end

      def super_admin_role
        'super_admin'
      end

      def auto_approved_admin_name
        ''
      end

      ### Role End ###

      # super admin Emails in staging/developemt should have this suffix for superadmins
      def sandbox_email_suffix
        "sandbox@"
      end

      ### Terms Of Use Start ###

      def accepted_terms_of_use
        'accepted'
      end

      def not_accepted_terms_of_use
        'not_accepted'
      end


      #### notification types Start ###


      def notification_types_config
        @notification_types_config ||= {
            "#{manual_review_needed_notification_type}" => {
                display_text: "MANUAL REVIEW NEEDED",
                super_admin_mandatory: false,
                bitwise_value: 1
            },
            "#{billing_plan_notification_notification_type}" => {
                display_text: "BILLING PLAN NOTIFICATION",
                super_admin_mandatory: true,
                bitwise_value: 2
            },
            "#{whitelisting_balance_alert_notification_type}" => {
                display_text: "WHITELISTING BALANCE ALERT",
                super_admin_mandatory: true,
                bitwise_value: 4
            },
            "#{open_case_request_outcome_notification_type}" => {
                display_text: "REOPEN CASE RESULT",
                super_admin_mandatory: false,
                bitwise_value: 8
            },
            "#{contract_address_update_notification_type}" => {
                display_text: "CONTRACT ADDRESS UPDATE",
                super_admin_mandatory: true,
                bitwise_value: 16
            }
        }.deep_symbolize_keys
      end

      def manual_review_needed_notification_type
        "manual_review_needed"
      end

      def billing_plan_notification_notification_type
        "billing_plan_notification"
      end

      def whitelisting_balance_alert_notification_type
        "whitelisting_balance_alert"
      end

      def open_case_request_outcome_notification_type
        "open_case_request_outcome"
      end

      def contract_address_update_notification_type
        "contract_address_update"
      end


      # list of notification types (stringified) which should always be on for super admins
      #
      # * Author: Aman
      # * Date: 24/01/2019
      # * Reviewed By:
      #
      # @returns [Array<String>] - A list of notification types (stringified) which should always be on for super admins
      #
      def notifications_mandatory_for_super_admins
        @notifications_mandatory_for_super_admins ||= notification_types_config.map {|x, y|
          x.to_s if y[:super_admin_mandatory]
        }.compact
      end

      # list of active admins who should receive a particular notification
      #
      # * Author: Aman
      # * Date: 24/01/2019
      # * Reviewed By:
      #
      # @param [String] client_id
      # @param [String] notification_type
      #
      # @returns [Array<AR>] - An array of Admin AR objects
      #
      def get_all_admins_for(client_id, notification_type)
        notification_type = notification_type.to_s
        admins = ::Admin.get_all_admins_from_memcache(client_id)
        res = []

        admins.each do |admin_obj|
          res << admin_obj if admin_obj.notification_types_array.include?(notification_type)
        end
        res
      end

      # list of active admins emails who should receive a particular notification
      #
      # * Author: Aman
      # * Date: 24/01/2019
      # * Reviewed By:
      #
      # @param [String] client_id
      # @param [String] notification_type
      #
      # @returns [Array<String>] - An array of Admin email ids
      #
      def get_all_admin_emails_for(client_id, notification_type)
        admin_objs = get_all_admins_for(client_id, notification_type)
        admin_objs.pluck(:email)
      end

      #### notification types End ###


      ### Terms Of Use End ###

      def admin_terms_of_use_hash
        {
            "v1" => {
                "text" => "Effective 22 January 2019, by selecting “agree”, you are agreeing to <b>Acuris Risk Intelligence replacing Cynopsis Solutions Pte. Ltd as your external compliance provider</b> and you now will be able to make all of your AML/CTF decisions on the OST KYC platform. All other terms of your OST Software as a Service (SaaS) subscription agreement shall remain in force."
            }
        }
      end

      def latest_admin_terms_of_use_version
        @latest_admin_terms_of_use_version ||= admin_terms_of_use_hash.keys[-1]
      end

      def latest_admin_terms_of_use
        @latest_admin_terms_of_use ||= admin_terms_of_use_hash[latest_admin_terms_of_use_version]
      end

    end

  end

end

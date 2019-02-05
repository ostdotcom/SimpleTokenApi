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

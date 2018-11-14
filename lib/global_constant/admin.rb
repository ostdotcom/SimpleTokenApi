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
        "+sandbox@"
      end

    end

  end

end

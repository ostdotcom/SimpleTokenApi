# frozen_string_literal: true
module GlobalConstant

  class Admin

    class << self

      ### Status Start ###

      def active_status
        'active'
      end

      def inactive_status
        'inactive'
      end

      def deactived_status
        'deactived'
      end

      ### Status End ###

      ### Role Start ###

      def normal_admin_role
        'normal_admin'
      end

      def super_admin_role
        'super_admin'
      end

      ### Role End ###
      #
    end

  end

end

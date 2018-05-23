# frozen_string_literal: true
module GlobalConstant

  class UserEmailDuplicationLog

    class << self

      ### Status Start ###

      def active_status
        'active'
      end

      def inactive_status
        'inactive'
      end

      ### Status End ###
      #

      def email_duplicate_type
        'email'
      end

    end

  end

end

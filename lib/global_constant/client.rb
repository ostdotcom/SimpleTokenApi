# frozen_string_literal: true
module GlobalConstant

  class Client

    class << self

      ### Status Start ###

      def active_status
        'active'
      end

      def inactive_status
        'inactive'
      end

      ### Status End ###

      ### setup Property start ###

      def cynopsis_setup_done
        "cynopsis_setup_done"
      end

      def email_setup_done
        "email_setup_done"
      end

      def whiteliste_setup_done
        "whiteliste_setup_done"
      end

      ### setup Property done ###

    end

  end

end

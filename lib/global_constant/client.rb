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

      def aml_setup_done
        "aml_setup_done"
      end

      def email_setup_done
        "email_setup_done"
      end

      def whitelist_setup_done
        "whitelist_setup_done"
      end

      def web_host_setup_done
        "web_host_setup_done"
      end

      def double_opt_in_setup_needed
        "double_opt_in_setup_needed"
      end

      ### setup Property done ###

      def sandbox_prefix_uuid
        "sandbox_"
      end

    end

  end

end

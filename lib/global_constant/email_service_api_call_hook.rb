# frozen_string_literal: true
module GlobalConstant

  class EmailServiceApiCallHook

    class << self

      ########## event_types #############

      def add_contact_event_type
        'add_contact'
      end

      def update_contact_event_type
        'update_contact'
      end

      def send_double_opt_in_mail_event_type
        'send_double_opt_in_mail'
      end

      ########## entity_types #############

    end

  end

end

# frozen_string_literal: true
module GlobalConstant

  class UserKycWhitelistLog

    class << self

      ### Status Start ###

      def pending_status
        'pending'
      end

      def update_event_obtained_status
        'update_event_obtained'
      end

      def attention_needed_status
        'attention_needed'
      end

      def confirmed_status
        'confirmed'
      end

      def failed_status
        'failed'
      end

      ### Status End ###

    end

  end

end

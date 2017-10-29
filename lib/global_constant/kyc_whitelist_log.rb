# frozen_string_literal: true
module GlobalConstant

  class KycWhitelistLog

    class << self

      ### Status Start ###

      def pending_status
        'pending'
      end

      def done_status
        'update_event_obtained'
      end

      def confirmed_status
        'confirmed'
      end

      ### Status End ###

      ### is attention needed starts ####

      def attention_not_needed
        'attention_not_needed'
      end

      def attention_needed
        'attention_needed'
      end

      ### is attention needed ends ####

      def kyc_whitelist_confirmation_pending_statuses
        [
            pending_status,
            done_status
        ]
      end

    end

  end

end

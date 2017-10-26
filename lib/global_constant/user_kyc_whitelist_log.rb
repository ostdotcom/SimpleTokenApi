# frozen_string_literal: true
module GlobalConstant

  class UserKycWhitelistLog

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
        0
      end

      def attention_needed
        1
      end

      ### is attention needed ends ####

    end

  end

end

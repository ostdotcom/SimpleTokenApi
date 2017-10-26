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

      ### Attention needed Start ###

      def false_attention_needed
        'false'
      end

      def true_attention_needed
        'true'
      end

      ### Attention needed End ###

    end

  end

end

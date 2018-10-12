module GlobalConstant

  class WebhookSendLog

    class << self

      ### STATUS start ###

      def unprocessed_status
        'unprocessed'
      end

      def failed_status
        'failed'
      end

      def expired_status
        'expired'
      end

      def invalid_status
        'invalid'
      end

      ### STATUS end ###

    end

  end
end

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

      def not_valid_status
        'not_valid'
      end

      ### STATUS end ###

    end

  end
end

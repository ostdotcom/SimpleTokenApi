module GlobalConstant
  class ClientWebhookSetting
    MAX_WEBHOOK_COUNT = 3

    class << self

      ### STATUS start ###

      def active_status
        'active'
      end

      def inactive_status
        'inactive'
      end

      def deleted_status
        'deleted'
      end

      ### STATUS end ###

    end
  end
end

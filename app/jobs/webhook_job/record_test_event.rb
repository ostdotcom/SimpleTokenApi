module WebhookJob

  class RecordTestEvent < Base

    queue_as GlobalConstant::Sidekiq.queue_name :default_high_priority_queue

    # Perform
    #
    # * Author: Aman
    # * Date: 20/10/2017
    # * Reviewed By: Sunil
    #
    def perform(params)
      super
    end

    private

    # Init params
    # parameters: client_id, event_type, event_source, event_name, event_data, event_timestamp, client_webhook_setting_id
    #
    # * Author: Aman
    # * Date: 11/10/2018
    # * Reviewed By:
    #
    #
    def init_params(params)
      super
      @client_webhook_setting_id = params[:client_webhook_setting_id].to_i
      @lock_id = params[:lock_id]
    end

    # validate events
    #
    # * Author: Aman
    # * Date: 11/10/2018
    # * Reviewed By:
    #
    def validate
      r = super
      return unless r

      return false if client_webhook_setting.blank? || client_webhook_setting.client_id != @client_id
      true
    end

    # get client webhook settings from memcache
    #
    # * Author: Aman
    # * Date: 11/10/2018
    # * Reviewed By:
    #
    def client_webhook_setting
      @client_webhook_setting ||= ClientWebhookSetting.get_from_memcache(@client_webhook_setting_id)
    end

    # get all client webhook settings from memcache
    #
    # * Author: Aman
    # * Date: 11/10/2018
    # * Reviewed By:
    #
    def client_webhook_settings
      @client_webhook_settings ||= [client_webhook_setting]
    end

  end
end
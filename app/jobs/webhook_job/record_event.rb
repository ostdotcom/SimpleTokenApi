module WebhookJob

  class RecordEvent < Base

    queue_as GlobalConstant::Sidekiq.queue_name :default_medium_priority_queue

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
    # parameters: client_id, event_type, event_source, event_name, event_data, event_timestamp
    #
    # * Author: Aman
    # * Date: 11/10/2018
    # * Reviewed By:
    #
    #
    def init_params(params)
      super
    end

  end
end
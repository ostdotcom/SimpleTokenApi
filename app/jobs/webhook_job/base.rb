module WebhookJob

  class Base < ApplicationJob

    # Perform
    #
    # * Author: Aman
    # * Date: 20/10/2017
    # * Reviewed By: Sunil
    #
    def perform(params)
      init_params(params)

      r = validate
      return unless r

      filter_events_subscription
      create_events_and_webhook_send_logs
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
      @params = params
      @client_id = params[:client_id].to_i
      @event_source = params[:event_source]
      @event_name = params[:event_name]
      @event_data = params[:event_data]
      @event_timestamp = params[:event_timestamp].to_i

      @filtered_webhook_settings = []
      @event_obj = {}
      @lock_id = nil
    end

    # validate events
    #
    # * Author: Aman
    # * Date: 11/10/2018
    # * Reviewed By:
    #
    def validate
      notify_devs and return false if @client_id < 1 ||
          Event.sources.keys.exclude?(@event_source) ||
          Event.names.keys.exclude?(@event_name) ||
          @event_data.blank? ||
          @event_timestamp == 0 ||
          Event::NAME_CONFIG[@event_name.to_s][:inavlid_source].include?(@event_source)
      true
    end

    # get webhook settings who have subscribed to this event
    #
    # * Author: Aman
    # * Date: 11/10/2018
    # * Reviewed By:
    #
    def filter_events_subscription
      client_webhook_settings.each do |cws|
        @filtered_webhook_settings << cws if cws.event_result_types_array.include?(event_type) && cws.event_sources_array.include?(@event_source)
      end
    end

    # create webhook evemnt and send log entries
    #
    # * Author: Aman
    # * Date: 11/10/2018
    # * Reviewed By:
    #
    def create_events_and_webhook_send_logs
      return if @filtered_webhook_settings.blank?

      @event_obj = Event.create!(
          client_id: @client_id,
          source: @event_source,
          name: @event_name,
          result_type: event_type,
          timestamp: @event_timestamp,
          data: encrypted_data
      )

      @filtered_webhook_settings.each do |cws|

        WebhookSendLog.create!(
            client_id: @client_id,
            client_webhook_setting_id: cws.id,
            event_id: @event_obj.id,
            next_timestamp: Time.now.to_i,
            status: GlobalConstant::WebhookSendLog.unprocessed_status,
            failed_count: 0,
            lock_id: @lock_id
        )
      end
    end

    # get encrypted event data
    #
    # * Author: Aman
    # * Date: 11/10/2018
    # * Reviewed By:
    #
    # returns[String] encrypted string for event data
    #
    def encrypted_data
      formatted_data = formatted_event_data
      encryptor_obj = LocalCipher.new(GlobalConstant::SecretEncryptor.webhook_event_secret_key)
      r = encryptor_obj.encrypt(formatted_data)
      fail "r: #{r}, params: #{@params}" unless r.success?

      r.data[:ciphertext_blob]
    end

    # get formatted event data
    #
    # * Author: Aman
    # * Date: 11/10/2018
    # * Reviewed By:
    #
    def formatted_event_data
      @get_formatter_class ||= begin
        case event_type
          when GlobalConstant::Event.user_result_type
            Formatter::V2::Users.show(@event_data)
          when GlobalConstant::Event.user_kyc_result_type
            Formatter::V2::UsersKyc.show(@event_data)
          else
            fail 'invalid event type'
        end
      end
    end

    # get result type
    #
    # * Author: Aman
    # * Date: 11/10/2018
    # * Reviewed By:
    #
    def event_type
      @event_type ||= Event.get_event_result_type(@event_name)
    end

    # get all client webhook settings from memcache
    #
    # * Author: Aman
    # * Date: 11/10/2018
    # * Reviewed By:
    #
    def client_webhook_settings
      @client_webhook_settings ||= ClientWebhookSetting.get_active_from_memcache(@client_id)
    end

    # notify devs if required
    #
    # * Author: Aman
    # * Date: 11/10/2018
    # * Reviewed By:
    #
    def notify_devs
      ApplicationMailer.notify(
          body: '',
          data: {params: @params},
          subject: 'Invalid Event data for WebhookJob::RecordEvent'
      ).deliver
    end

  end
end
module Crons

  class WebhookProcessor

    include Util::ResultHelper

    MAX_RUN_TIME = 5.minutes
    MAX_FAILED_COUNT = 7

    # initialize
    #
    # * Author: Aman
    # * Date: 15/10/2018
    # * Reviewed By:
    #
    # @param [Boolean] cron_identifier (mandatory) : unique_identifier of a cron job
    #
    # @return [Crons::WebhookProcessor]
    #
    def initialize(params = {})
      @cron_identifier = params[:cron_identifier]
      fail 'Missing cron identifier' if cron_identifier.blank?

      @start_timestamp = nil
      @iteration_count = 0
    end

    # public method to process hooks
    #
    # * Author: Aman
    # * Date: 15/10/2018
    # * Reviewed By:
    #
    def perform
      return if client_webhook_setting.blank?

      webhook_send_logs_to_process do |w_s_logs|
        event_ids = w_s_logs.pluck(:event_id)
        events = Event.where(id: event_ids, client_id: client_webhook_setting.client_id).all.index_by(:id)

        w_s_logs.each do |w_s_log|
          event = events[w_s_log.event_id]

          if is_valid_event?(event)

            r = process_event(event)
            if r.success?
              w_s_log.status = GlobalConstant::WebhookSendLog.processed_status
            else
              increase_failed_count(w_s_log)
            end

          else
            w_s_log.status = GlobalConstant::WebhookSendLog.not_valid_status
          end
          w_s_log.lock_id = nil
          w_s_log.save!
        end

      end


      client_webhook_setting.last_processed_at = current_timestamp
      client_webhook_setting.save!

    end

    # Process event
    #
    # * Author: Aman
    # * Date: 15/10/2018
    # * Reviewed By:
    #
    # @returns [Result::Base] returns success result base if successfully processed
    #
    def process_event(event)
      begin
        # todo:  some_lib(@client_webhook_setting, event)
      rescue => se
        return exception_with_data(
            se,
            'j_wp_pe_1',
            'exception in webhook event process: ' + se.message,
            'Something went wrong.',
            GlobalConstant::ErrorAction.default,
            {client_webhook_setting: client_webhook_setting, event: event}
        )

      end
    end

    # check if event is still a valid event for the webhook based on the applied filters
    #
    # * Author: Aman
    # * Date: 15/10/2018
    # * Reviewed By:
    #
    # @returns [Boolean] returns true if event is sill applicaple as per webhook settings
    #
    def is_valid_event?(event)
      client_webhook_setting.event_result_types_array.include?(event.result_type) &&
          client_webhook_setting.event_sources_array.include?(event.source)
    end

    # update webhook_send_log if processing failed
    #
    # * Author: Aman
    # * Date: 15/10/2018
    # * Reviewed By:
    #
    def increase_failed_count(w_s_log)
      w_s_log.failed_count = w_s_log.failed_count.to_i + 1

      if w_s_log.failed_count >= MAX_FAILED_COUNT
        w_s_log.status = GlobalConstant::WebhookSendLog.expired_status
      else
        w_s_log.status = GlobalConstant::WebhookSendLog.failed_status
        w_s_log.next_timestamp = Time.now.to_i + (1.hour.to_i * (2**(w_s_log.failed_count-1)))
      end

    end

    # get lock on webhook send logs to be processed
    #
    # * Author: Aman
    # * Date: 15/10/2018
    # * Reviewed By:
    #
    def webhook_send_logs_to_process
      start_timestamp = current_timestamp
      while (true)
        @iteration_count += 1
        lock_id = get_lock_id

        WebhookSendLog.to_be_processed.where(client_id: client_webhook_setting.client_id,
                                             client_webhook_setting_id: client_webhook_setting.id).
            where('next_timestamp > ?', current_timestamp).where('lock_id is null').
            update_all(lock_id: lock_id).order(next_timestamp: :asc).limit(10)

        ws_logs = WebhookSendLog.where(lock_id: lock_id).to_be_processed.all
        yield(ws_logs)
        return if ws_logs.blank? || (start_timestamp + MAX_RUN_TIME.to_i) < current_timestamp
      end

    end

    # generate a uniq lock id for each iteration
    #
    # * Author: Aman
    # * Date: 15/10/2018
    # * Reviewed By:
    #
    #  @returns [String] returns a lock id generated unique for each iteration
    #
    def get_lock_id
      "#{@cron_identifier}_#{Time.now.to_f}_#{client_webhook_setting.id}_#{@iteration_count}"
    end

    # get a client webhook setting to be processed based on last processed time
    #
    # * Author: Aman
    # * Date: 15/10/2018
    # * Reviewed By:
    #
    def client_webhook_setting
      @client_webhook_setting ||= ClientWebhookSetting.is_active.last_processed
    end

    # get current timestamp
    #
    # * Author: Aman
    # * Date: 15/10/2018
    # * Reviewed By:
    #
    # @returns [Integer] returns current time in epoch seconds
    #
    def current_timestamp
      Time.now.to_i
    end

  end

end
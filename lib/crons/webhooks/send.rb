module Crons
  module Webhooks

    class Send < Base

      MAX_FAILED_COUNT = 7

      # initialize
      #
      # * Author: Aman
      # * Date: 15/10/2018
      # * Reviewed By:
      #
      # @param [String] cron_identifier (mandatory) : unique_identifier of a cron job
      #
      # @return [Crons::Webhooks::Send]
      #
      def initialize(params = {})
        super
        fail 'Missing cron identifier' if @cron_identifier.blank?

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
        process_logs_in_batches

        client_webhook_setting.last_processed_at = current_timestamp
        client_webhook_setting.save!
      end

      private

      # private method to process logs
      #
      # * Author: Aman
      # * Date: 15/10/2018
      # * Reviewed By:
      #
      def process_logs_in_batches
        start_timestamp = current_timestamp
        while (true)
          @iteration_count += 1
          lock_id = get_lock_id
          get_lock_on_records(lock_id)
          w_s_logs = fetch_logs(lock_id)

          process_webhook_logs(w_s_logs)

          return if w_s_logs.blank? || ((start_timestamp + MAX_RUN_TIME.to_i) < current_timestamp) ||
              GlobalConstant::SignalHandling.sigint_received?

        end

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

      # Max allowed failed count for events retry
      #
      # * Author: Aman
      # * Date: 15/10/2018
      # * Reviewed By:
      #
      #  @returns [Inteher] returns a Max allowed failed count for events retry
      #
      def max_failed_count
        MAX_FAILED_COUNT
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

    end

  end
end
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
      end

      # public method to process hooks
      #
      # * Author: Aman
      # * Date: 15/10/2018
      # * Reviewed By:
      #
      def perform
        return if client_webhook_setting.blank?
        process_logs

        client_webhook_setting.last_processed_at = current_timestamp
        client_webhook_setting.save!
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

    end

  end
end
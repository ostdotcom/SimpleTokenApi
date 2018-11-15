module Crons
  module Webhooks

    class TestSend < Base

      MAX_FAILED_COUNT = 1

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

        @lock_id = params[:lock_id]
        @client_webhook_setting_id = params[:client_webhook_setting_id].to_i
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
      end

      # get a client webhook setting to be processed
      #
      # * Author: Aman
      # * Date: 15/10/2018
      # * Reviewed By:
      #
      def client_webhook_setting
        @client_webhook_setting ||= ClientWebhookSetting.is_active.where(id: @client_webhook_setting_id).first
      end

      # lock has already been taken by the enquque process.
      #
      # * Author: Aman
      # * Date: 15/10/2018
      # * Reviewed By:
      #
      # @returns [String] returns unique Lock_id
      #
      def get_lock_on_records_with_lock_id
        @lock_id
      end

      # get lock id for test events to be processed
      #
      # * Author: Aman
      # * Date: 15/10/2018
      # * Reviewed By:
      #
      #  @returns [String] returns a lock id used for the test webhook logs creation
      #
      def get_lock_id
        @lock_id
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
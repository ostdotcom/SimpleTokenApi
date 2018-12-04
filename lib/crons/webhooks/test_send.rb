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
      # @param [String] lock_id (mandatory) : lock_id for the test webhook group
      #
      # @return [Crons::Webhooks::TestSend]
      #
      def initialize(params = {})
        super

        @lock_id = params[:lock_id]
        @client_webhook_setting_id = params[:client_webhook_setting_id].to_i
        @admin_id = params[:admin_id]
      end

      # public method to process hooks
      #
      # * Author: Aman
      # * Date: 15/10/2018
      # * Reviewed By:
      #
      def perform
        return if client_webhook_setting.blank?
        w_s_logs = fetch_logs(@lock_id)
        logs_data = process_webhook_logs(w_s_logs)
        send_admin_email(logs_data)
      end

      private

      # get a client webhook setting to be processed
      #
      # * Author: Aman
      # * Date: 15/10/2018
      # * Reviewed By:
      #
      def client_webhook_setting
        @client_webhook_setting ||= ClientWebhookSetting.is_active.where(id: @client_webhook_setting_id).first
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
      #  @returns [Integer] returns a Max allowed failed count for events retry
      #
      def max_failed_count
        MAX_FAILED_COUNT
      end

      # Send test webhook result email to admin
      #
      # * Author: Aman
      # * Date: 15/10/2018
      # * Reviewed By:
      #
      def send_admin_email(logs_data)
        return if logs_data.blank?

        test_send_data = []
        logs_data.each do |_, log_data|
          next if log_data[:status] == GlobalConstant::WebhookSendLog.not_valid_status

          test_send_data << {
              name: log_data[:event_name].humanize,
              status: log_data[:status]
          }
        end

        admin_email = Admin.where(id: @admin_id).first.email
        return if admin_email.blank?

        Email::HookCreator::SendTransactionalMail.new(
            client_id: Client::OST_KYC_CLIENT_IDENTIFIER,
            email: admin_email,
            template_name: GlobalConstant::PepoCampaigns.test_webhook_result_template,
            template_vars: {
                test_send_data: test_send_data,
                webhook_url: client_webhook_setting.url
            }
        ).perform

      end


    end

  end
end
module ClientManagement
  module WebhookSetting
    class Delete < ServicesBase
      # Initialize
      #
      # * Author: Tejas
      # * Date: 25/10/2018
      # * Reviewed By:
      #
      # @param [Integer] client_id (mandatory) - client id
      # @param [Integer] admin_id (mandatory) - admin id
      # @param [Integer] webhook_id (mandatory) - webhook id
      #
      #
      # @return [ClientManagement::WebhookSetting::Delete]
      #
      def initialize(params)
        super
        @client_id = @params[:client_id]
        @admin_id = @params[:admin_id]
        @webhook_id = @params[:webhook_id]

        @client_webhook_settings = nil
      end

      # Perform
      #
      # * Author: Tejas
      # * Date: 25/10/2018
      # * Reviewed By:
      #
      def perform
        r = validate_and_sanitize
        return r unless r.success?

        delete_client_webhook_setting

        enqueue_job

        success
      end

      private

      # Valdiate and sanitize
      #
      # * Author: Tejas
      # * Date: 25/10/2018
      # * Reviewed By:
      #
      # Sets client
      #
      def validate_and_sanitize

        r = validate
        return r unless r.success?

        r = fetch_and_validate_client
        return r unless r.success?

        r = fetch_and_validate_admin
        return r unless r.success?

        r = fetch_and_validate_webhook
        return r unless r.success?

        success
      end

      # Fetch And Validate Webhook
      #
      # * Author: Tejas
      # * Date: 25/10/2018
      # * Reviewed By:
      #
      # Sets @client_webhook_setting
      #
      def fetch_and_validate_webhook
        @client_webhook_setting = ClientWebhookSetting.get_from_memcache(@webhook_id)
        return error_with_identifier('resource_not_found', 'cm_dw_favw_1'
        ) if @client_webhook_setting.blank? || @client_webhook_setting.status != GlobalConstant::ClientWebhookSetting.active_status ||
            @client_webhook_setting.client_id != @client_id
        success
      end

      # Delete Client Webhook Setting
      #
      # * Author: Tejas
      # * Date: 25/10/2018
      # * Reviewed By:
      #
      def delete_client_webhook_setting
        @client_webhook_setting.status = GlobalConstant::ClientWebhookSetting.deleted_status
        @client_webhook_setting.source = GlobalConstant::AdminActivityChangeLogger.web_source
        @client_webhook_setting.save! if @client_webhook_setting.changed?
      end

      # Do remaining task in sidekiq
      #
      # * Author: Tejas
      # * Date: 25/10/2018
      # * Reviewed By:
      #
      def enqueue_job
        BgJob.enqueue(
            InvalidWebhookJob,
            {
                client_id: @client_id,
                client_webhook_setting_id: @webhook_id,
            }
        )
      end

    end
  end
end
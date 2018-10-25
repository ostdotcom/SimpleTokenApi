module ClientManagement
  module Webhook
    class Update < Base

      # Initialize
      #
      # * Author: Tejas
      # * Date: 25/10/2018
      # * Reviewed By:
      #
      # @param [Integer] client_id (mandatory) -  client id
      # @param [Integer] admin_id (mandatory) - admin id
      # @param [Integer] webhook_id (mandatory) - webhook id
      # @param [String] url (mandatory) - url
      # @param [Array] event_sources (mandatory) - event sources
      # @param [Array] event_result_types (mandatory) - event result types
      #
      #
      # @return [ClientManagement::Webhook::Update]
      #
      def initialize(params)
        super

        @webhook_id = @params[:webhook_id]
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

        update_client_webhook_setting

        success_with_data(webhook: @client_webhook_setting.get_hash)
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
        r = fetch_and_validate_webhook
        return r unless r.success?

        super
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
        return error_with_identifier('resource_not_found', 'cm_uw_favcws_1'
        ) if @client_webhook_setting.blank? || @client_webhook_setting.status != GlobalConstant::ClientWebhookSetting.active_status ||
            @client_webhook_setting.client_id != @client_id
        success
      end

      # Update Client Webhook Setting
      #
      # * Author: Tejas
      # * Date: 25/10/2018
      # * Reviewed By:
      #
      def update_client_webhook_setting
        @client_webhook_setting.url = @url
        @client_webhook_setting.last_acted_by = @admin_id
        @client_webhook_setting.event_result_types = 0
        @client_webhook_setting.event_sources = 0

        @event_result_types.each do |event_result_type|
          @client_webhook_setting.send("set_" + event_result_type)
        end

        @event_sources.each do |event_source|
          @client_webhook_setting.send("set_" + event_source)
        end
        @client_webhook_setting.source = GlobalConstant::AdminActivityChangeLogger.web_source
        @client_webhook_setting.save! if @client_webhook_setting.changed?

      end

    end
  end
end


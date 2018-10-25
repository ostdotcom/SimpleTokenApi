module ClientManagement
  class GetWebhookDetail < ServicesBase

    # Initialize
    #
    # * Author: Tejas
    # * Date: 25/10/2018
    # * Reviewed By:
    #
    # @param [Integer] client_id (mandatory) -  client id
    # @param [Integer] admin_id (mandatory) - admin id
    #
    #
    # @return [ClientManagement::GetWebhookDetail]
    #
    def initialize(params)
      super
      @client_id = @params[:client_id]
      @admin_id = @params[:admin_id]

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

      fetch_client_webhook_settings

      success_with_data(service_response_data)
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

      success
    end

    # Fetch Client Webhook Settings
    #
    # * Author: Tejas
    # * Date: 25/10/2018
    # * Reviewed By:
    #
    # Sets @client_webhook_settings
    #
    def fetch_client_webhook_settings
      @client_webhook_settings = ClientWebhookSetting.get_active_from_memcache(@client_id)
    end

    # Get Event Source
    #
    # * Author: Tejas
    # * Date: 25/10/2018
    # * Reviewed By:
    #
    def get_event_source
      event_sources_hash = {}
      Event.sources.keys.each do |source|
        event_sources_hash[source] = {selected: true, display_text: source.titleize}
      end
      event_sources_hash
    end

    # Get Event Result Types
    #
    # * Author: Tejas
    # * Date: 25/10/2018
    # * Reviewed By:
    #
    def get_event_result_types
      event_result_types_hash = {}
      Event.result_types.keys.each do |result_type|
        event_result_types_hash[result_type] = {selected: true, display_text: result_type.titleize}
      end
      event_result_types_hash
    end

    # Format service response
    #
    # * Author: Tejas
    # * Date: 25/10/2018
    # * Reviewed By:
    #
    def service_response_data
      {
          webhooks: @client_webhook_settings.map{|x| x.get_hash},
          config: {
              event_sources: get_event_source,
              event_result_types: get_event_result_types,
              max_webhook_count: GlobalConstant::ClientWebhookSetting::MAX_WEBHOOK_COUNT
          }
      }
    end

  end
end


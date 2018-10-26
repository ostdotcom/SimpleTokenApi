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
      event_sources_array = []
      Event.sources.keys.each do |source|
        event_sources_array << {key: "event_sources", value: source, display_text: source.titleize}
      end
      event_sources_array
    end

    # Get Event Result Types
    #
    # * Author: Tejas
    # * Date: 25/10/2018
    # * Reviewed By:
    #
    def get_event_result_types
      event_result_types_array = []
      Event.result_types.keys.each do |result_type|
        event_result_types_array << [key: "event_result_types", value:result_type,  display_text: result_type.titleize]
      end
      event_result_types_array
    end

    # # Get Decrypted Secret Key
    # #
    # # * Author: Tejas
    # # * Date: 25/10/2018
    # # * Reviewed By:
    # #
    # def get_decrypted_secret_key
    #   r = Aws::Kms.new('saas', 'saas').decrypt(@client.api_salt)
    #   return r unless r.success?
    #
    #   api_salt_d = r.data[:plaintext]
    #
    #   @client_webhook_settings.each do |client_webhook_setting|
    #     r = LocalCipher.new(api_salt_d).decrypt(client_webhook_setting.secret_key)
    #     return r unless r.success?
    #     client_api_secret_d = r.data[:plaintext]
    #     client_webhook_setting.set_decrypted_secret_key(client_api_secret_d)
    #   end
    #
    # end

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


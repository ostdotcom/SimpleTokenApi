module ClientManagement
  module Webhook
    class Create < Base

      # Initialize
      #
      # * Author: Tejas
      # * Date: 25/10/2018
      # * Reviewed By:
      #
      # @param [Integer] client_id (mandatory) -  client id
      # @param [Integer] admin_id (mandatory) - admin id
      # @param [String] url (mandatory) - url
      # @param [Array] event_sources (mandatory) - event sources
      # @param [Array] event_result_types (mandatory) - event result types
      #
      #
      # @return [ClientManagement::Webhook::Create]
      #
      def initialize(params)
        super
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

        create_client_webhook_setting

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
        super
      end

      # Generate Secret Key
      #
      # * Author: Tejas
      # * Date: 25/10/2018
      # * Reviewed By:
      #
      def generate_secret_key
        r = Aws::Kms.new('saas', 'saas').decrypt(@client.api_salt)
        return r unless r.success?

        api_salt_d = r.data[:plaintext]

        client_api_secret_d = SecureRandom.hex

        r = LocalCipher.new(api_salt_d).encrypt(client_api_secret_d)
        return r unless r.success?

        {e_secret_key: r.data[:ciphertext_blob], d_secret_key: client_api_secret_d}
      end

      # Create Client Webhook Setting
      #
      # * Author: Tejas
      # * Date: 25/10/2018
      # * Reviewed By:
      #
      # sets @client_webhook_setting
      #
      def create_client_webhook_setting
        @client_webhook_setting = ClientWebhookSetting.new(client_id: @client_id,
                                             status: GlobalConstant::ClientWebhookSetting.active_status,
                                             url: @url,
                                             event_result_types: 0,
                                             event_sources: 0,
                                             last_acted_by: @admin_id,
                                             last_processed_at: Time.now.to_i,
                                             source: GlobalConstant::AdminActivityChangeLogger.web_source
                                             )


        r = generate_secret_key
        @client_webhook_setting.secret_key = r[:e_secret_key]
        @client_webhook_setting.set_decrypted_secret_key(r[:d_secret_key])


        @event_result_types.each do |event_result_type|
          @client_webhook_setting.send("set_" + event_result_type)
        end

        @event_sources.each do |event_source|
          @client_webhook_setting.send("set_" + event_source)
        end
        @client_webhook_setting.save!
      end

    end
  end
end



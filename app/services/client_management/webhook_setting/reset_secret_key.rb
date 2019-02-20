module ClientManagement
  module WebhookSetting
    class ResetSecretKey < ServicesBase
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
      # @return [ClientManagement::WebhookSetting::ResetSecretKey]
      #
      def initialize(params)
        super
        @client_id = @params[:client_id]
        @admin_id = @params[:admin_id]
        @webhook_id = @params[:webhook_id]

        @client_webhook_setting = nil
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

        reset_secret_key

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
        return error_with_identifier('resource_not_found', 'cm_gsk_favw_1'
        ) if @client_webhook_setting.blank? || @client_webhook_setting.status != GlobalConstant::ClientWebhookSetting.active_status ||
            @client_webhook_setting.client_id != @client_id
        success
      end

      # Reset Secret Key
      #
      # * Author: Tejas
      # * Date: 25/10/2018
      # * Reviewed By:
      #
      def reset_secret_key
        r = Aws::Kms.new('saas', 'saas').decrypt(@client.api_salt)
        return r unless r.success?

        api_salt_d = r.data[:plaintext]

        client_api_secret_d = SecureRandom.hex

        r = LocalCipher.new(api_salt_d).encrypt(client_api_secret_d)
        return r unless r.success?

        client_api_secret_e = r.data[:ciphertext_blob]

        @client_webhook_setting.secret_key = client_api_secret_e
        @client_webhook_setting.set_decrypted_secret_key(client_api_secret_d)
        @client_webhook_setting.source = GlobalConstant::AdminActivityChangeLogger.web_source
        @client_webhook_setting.last_acted_by = @admin_id
        @client_webhook_setting.save! if @client_webhook_setting.changed?
      end

      # Format service response
      #
      # * Author: Tejas
      # * Date: 25/10/2018
      # * Reviewed By:
      #
      def service_response_data
        {
            webhook: @client_webhook_setting.get_hash
        }
      end

    end
  end
end

module ClientManagement
  module WebhookSetting

    class Test < ServicesBase

      # Initialize
      #
      # * Author: Aman
      # * Date: 15/11/2018
      # * Reviewed By:
      #
      # @param [Integer] client_id (mandatory) - client id
      # @param [Integer] admin_id (mandatory) - admin id
      # @param [Integer] webhook_id (mandatory) - webhook id
      #
      #
      # @return [ClientManagement::WebhookSetting::Test]
      #
      def initialize(params)
        super
        @client_id = @params[:client_id]
        @admin_id = @params[:admin_id]
        @webhook_id = @params[:webhook_id]

        @client_webhook_setting = nil
        @valid_events = {}
      end

      # Perform
      #
      # * Author: Aman
      # * Date: 15/11/2018
      # * Reviewed By:
      #
      def perform
        r = validate_and_sanitize
        return r unless r.success?

        fetch_valid_test_events

        return error_with_identifier('could_not_proceed',
                                     'cm_ws_t_p_1', [],
                                     'There are no events for the applied filters') if @valid_events.values.length == 0

        enqueue_events

        success_with_data(service_response_data)
      end

      private

      # Valdiate and sanitize
      #
      # * Author: Aman
      # * Date: 15/11/2018
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
      # * Author: Aman
      # * Date: 15/11/2018
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

      # fetch all valid test events for webhook
      #
      # * Author: Aman
      # * Date: 15/11/2018
      # * Reviewed By:
      #
      def fetch_valid_test_events
        Event::NAME_CONFIG.each do |name, e_data|

          @client_webhook_setting.event_sources_array.each do |event_source|
            @client_webhook_setting.event_result_types_array.each do |result_type|

              next if result_type != e_data[:result_type] ||
                  e_data[:inavlid_source].include?(event_source)

              event_data = GlobalConstant::Event.send("#{name}_event_data")

              if event_source == GlobalConstant::Event.kyc_system_source
                event_data[:user_kyc_detail][:last_acted_by] = Admin::AUTO_APPROVE_ADMIN_ID
              end

              event = {
                  client_id: @client_id,
                  event_source: event_source,
                  event_name: name,
                  event_data: event_data,
                  event_timestamp: Time.now.to_i,

                  client_webhook_setting_id: @webhook_id,
                  lock_id: lock_id
              }

              @valid_events[name] ||= []
              @valid_events[name] << event
            end
          end
        end
      end

      # Enqueue test events
      #
      # * Author: Aman
      # * Date: 15/11/2018
      # * Reviewed By:
      #
      def enqueue_events
        @valid_events.each do |_, events|
          WebhookJob::RecordTestEvent.perform_now(events[0])
        end

        BgJob.enqueue(
            ProcessTestWebhookEvents,
            {
                lock_id: lock_id,
                client_webhook_setting_id: @webhook_id,
                admin_id: @admin_id
            }
        )
      end

      # Lock id for webhook_send_logs for test events
      #
      # * Author: Aman
      # * Date: 15/11/2018
      # * Reviewed By:
      #
      def lock_id
        @lock_id ||= "test_#{Time.now.to_f}_#{@client_webhook_setting.id}_1"
      end

      # Format service response
      #
      # * Author: Aman
      # * Date: 15/11/2018
      # * Reviewed By:
      #
      def service_response_data
        {
            webhook: @client_webhook_setting.get_hash,
            test_send_id: lock_id
        }
      end

    end
  end

end
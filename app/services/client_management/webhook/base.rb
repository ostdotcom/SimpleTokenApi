module ClientManagement
  module Webhook
    class Base < ServicesBase

      # Initialize
      #
      # * Author: Tejas
      # * Date: 25/10/2018
      # * Reviewed By:
      #
      # @param [Integer] client_id (mandatory) -  client id
      # @param [Integer] admin_id (mandatory) -  admin id
      #
      # @return [ClientManagement::Webhook::Base]
      #
      def initialize(params)
        super

        @client_id = @params[:client_id]
        @admin_id = @params[:admin_id]

        @url = @params[:url]
        @event_sources = @params[:event_sources]
        @event_result_types = @params[:event_result_types]

        @client_webhook_settings = []
        @client_webhook_setting = nil

        @client = nil
        @admin = nil
      end

      # Perform
      #
      # * Author: Tejas
      # * Date: 25/10/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform
        r = validate_and_sanitize
        return r unless r.success?

        success
      end

      private

      # Validate And Sanitize
      #
      # * Author: Tejas
      # * Date: 25/10/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def validate_and_sanitize
        r = validate
        return r unless r.success?

        r = fetch_and_validate_client
        return r unless r.success?

        r = fetch_and_validate_admin
        return r unless r.success?

        r = validate_event_source
        return r unless r.success?

        r = validate_event_result_type
        return r unless r.success?

        r = fetch_and_validate_client_webhook_settings
        return r unless r.success?

        r = validate_url
        return r unless r.success?

        success
      end

      # Fetch And Validate Client Webhook Settings
      #
      # * Author: Tejas
      # * Date: 25/10/2018
      # * Reviewed By:
      #
      # Sets @client_webhook_settings
      #
      def fetch_and_validate_client_webhook_settings
        all_client_webhook_settings = ClientWebhookSetting.get_active_from_memcache(@client_id)

        all_client_webhook_settings.each do |cws|
          @client_webhook_settings << cws if @client_webhook_setting.blank? || (cws.id != @client_webhook_setting.id)
        end


        return error_with_identifier('max_webhook_count_reached', 'cm_w_b_favcws_1'
        ) if @client_webhook_settings.size >= GlobalConstant::ClientWebhookSetting::MAX_WEBHOOK_COUNT
        success
      end

      # Validate URL
      #
      # * Author: Tejas
      # * Date: 25/10/2018
      # * Reviewed By:
      #
      #
      def validate_url
        return error_with_identifier('invalid_api_params',
                                     'cm_w_b_vu_1',
                                     ['invalid_url'],
                                     "The URL is invalid. Please try with other URL and resubmit it."
        ) unless Util::CommonValidateAndSanitize.is_string?(@url)

        uri_value = URI.parse(@url) rescue ""
        return error_with_identifier('invalid_api_params',
                                     'cm_w_b_vu_2',
                                     ['invalid_url'],
                                     "The URL is invalid. Please try with other URL and resubmit it."
        ) if uri_value.blank? || (URI::HTTPS != uri_value.class) || uri_value.host.blank? || uri_value.query.present?

        @client_webhook_settings.each do |client_webhook_setting|
          return error_with_identifier('invalid_api_params',
                                       'cm_w_b_vu_3',
                                       ['duplicate_url'],
                                       'The URL is duplicate. Please try with other URL and resubmit it.'
          ) if client_webhook_setting.url.downcase == @url.downcase
        end
        success
      end

      # Validate Event Sources
      #
      # * Author: Tejas
      # * Date: 25/10/2018
      # * Reviewed By:
      #
      #
      def validate_event_source
        return error_with_identifier('invalid_api_params',
                                     'cm_w_b_ves_1',
                                     ['invalid_event_sources']
        )if !(Util::CommonValidateAndSanitize.is_array?(@event_sources)) || ((@event_sources - Event.sources.keys).present?)
        success
      end

      # Validate Event Result Types
      #
      # * Author: Tejas
      # * Date: 25/10/2018
      # * Reviewed By:
      #
      #
      def validate_event_result_type
        return error_with_identifier('invalid_api_params',
                                     'cm_w_b_vert_1',
                                     ['invalid_event_result_types']
        )unless Util::CommonValidateAndSanitize.is_array?(@event_sources) || ((@event_result_types - Event.result_types.keys).present?)
        success
      end

    end
  end
end
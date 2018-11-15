module Crons
  module Webhooks

    class Base

      include Util::ResultHelper

      MAX_RUN_TIME = 5.minutes
      RETRY_INTERVAL_TIME_FACTOR = 1.hour

      # initialize
      #
      # * Author: Aman
      # * Date: 15/10/2018
      # * Reviewed By:
      #
      # @param [String] cron_identifier (mandatory) : unique_identifier of a cron job
      #
      # @return [Crons::Webhooks::Base]
      #
      def initialize(params = {})
        @cron_identifier = params[:cron_identifier]

        @start_timestamp = nil
        @iteration_count = 0
      end

      # private method to process logs
      #
      # * Author: Aman
      # * Date: 15/10/2018
      # * Reviewed By:
      #
      def process_logs
        webhook_send_logs_to_process do |w_s_logs|
          event_ids = w_s_logs.pluck(:event_id)
          events = Event.where(id: event_ids, client_id: client_webhook_setting.client_id).all.index_by(&:id)

          w_s_logs.each do |w_s_log|
            event = events[w_s_log.event_id]

            if is_valid_event?(event)
              r = process_event(w_s_log, event)
              if r.success?
                w_s_log.status = GlobalConstant::WebhookSendLog.processed_status
              else
                increase_failed_count(w_s_log)
              end

            else
              w_s_log.status = GlobalConstant::WebhookSendLog.not_valid_status
            end
            w_s_log.save!
          end
        end
      end

      # Process event
      #
      # * Author: Aman
      # * Date: 15/10/2018
      # * Reviewed By:
      #
      # @returns [Result::Base] returns success result base if successfully processed
      #
      def process_event(w_s_log, event)
        begin
          data_to_send = get_formatted_data(w_s_log, event)
          request_parameters = generate_and_merge_signature(data_to_send)
          http_request_params = {
              url: client_webhook_setting.url,
              request_parameters: request_parameters
          }
          r = HttpHelper::HttpRequest.new(http_request_params).post
          return r unless r.success?

          parse_api_response(r.data[:http_response])
        rescue => se
          return exception_with_data(
              se,
              'j_wp_pe_1',
              'exception in webhook event process: ' + se.message,
              'Something went wrong.',
              GlobalConstant::ErrorAction.default,
              {client_webhook_setting: client_webhook_setting, w_s_log: w_s_log}
          )

        end
      end

      # check if event is still a valid event for the webhook based on the applied filters
      #
      # * Author: Aman
      # * Date: 15/10/2018
      # * Reviewed By:
      #
      # @returns [Boolean] returns true if event is sill applicaple as per webhook settings
      #
      def is_valid_event?(event)
        client_webhook_setting.event_result_types_array.include?(event.result_type) &&
            client_webhook_setting.event_sources_array.include?(event.source)
      end

      # update webhook_send_log if processing failed
      #
      # * Author: Aman
      # * Date: 15/10/2018
      # * Reviewed By:
      #
      def increase_failed_count(w_s_log)
        w_s_log.failed_count = w_s_log.failed_count.to_i + 1

        if w_s_log.failed_count >= max_failed_count
          w_s_log.status = GlobalConstant::WebhookSendLog.expired_status
        else
          w_s_log.status = GlobalConstant::WebhookSendLog.failed_status
          w_s_log.next_timestamp = current_timestamp + (RETRY_INTERVAL_TIME_FACTOR.to_i * (2 ** (w_s_log.failed_count - 1)))
          w_s_log.lock_id = nil
        end

      end

      # get lock on webhook send logs to be processed
      #
      # * Author: Aman
      # * Date: 15/10/2018
      # * Reviewed By:
      #
      def webhook_send_logs_to_process
        start_timestamp = current_timestamp
        while (true)
          @iteration_count += 1
          lock_id = get_lock_on_records_with_lock_id

          ws_logs = WebhookSendLog.where(lock_id: lock_id).to_be_processed.all
          yield(ws_logs)
          return if ws_logs.blank? || ((start_timestamp + MAX_RUN_TIME.to_i) < current_timestamp) ||
              GlobalConstant::SignalHandling.sigint_received?
        end
      end

      # get lock on webhook send logs
      #
      # * Author: Aman
      # * Date: 15/10/2018
      # * Reviewed By:
      #
      # @returns [String] returns unique Lock_id
      #
      def get_lock_on_records_with_lock_id
        lock_id = get_lock_id
        WebhookSendLog.to_be_processed.where(client_id: client_webhook_setting.client_id,
                                             client_webhook_setting_id: client_webhook_setting.id).
            where('next_timestamp < ?', current_timestamp).where('lock_id is null').
            order(next_timestamp: :asc).limit(10).update_all(lock_id: lock_id)
        lock_id
      end

      # get formatted event data
      #
      # * Author: Aman
      # * Date: 15/10/2018
      # * Reviewed By:
      #
      # @returns [Hash] returns hash of event data for webhook
      #
      def get_formatted_data(webhook_send_log, event)
        {
            id: webhook_send_log.id,
            name: event.name,
            type: event.result_type,
            description: Event.get_event_description(event.name),
            version: GlobalConstant::WebhookSendLog.v1,
            source: event.source,
            data: decrypted_event_data(event.data),
            created_at: event.timestamp,
            request_timestamp: current_timestamp
        }
      end

      # get decrypted event data
      #
      # * Author: Aniket
      # * Date: 22/10/2018
      # * Reviewed By:
      #
      # returns[String] decrypted string for event data
      #
      def decrypted_event_data(data_to_decrypt)
        decryptor_obj = LocalCipher.new(GlobalConstant::SecretEncryptor.webhook_event_secret_key)
        r = decryptor_obj.decrypt(data_to_decrypt)
        fail "Error in event data decryption r: #{r}, data_to_decrypt: #{data_to_decrypt}" unless r.success?

        r.data[:plaintext]
      end

      def generate_and_merge_signature(data_to_send)
        signature_params = {url: client_webhook_setting.url,
                            api_secret: client_webhook_setting.decrypted_secret_key,
                            request_parameters: data_to_send
        }
        signature = HttpHelper::SignatureGenerator.new(signature_params).perform
        data_to_send.merge!(signature: signature)
      end


      def parse_api_response(http_response)
        response_data = Oj.load(http_response.body, mode: :strict) rescue {}

        Rails.logger.info("=*=HTTP-Response*= #{response_data.inspect}")
        puts "http_response.class.name : #{http_response.class.name}"

        case http_response.class.name
          when 'Net::HTTPOK'
            success_result(response_data)
          when 'Net::HTTPBadRequest'
            # 400
            error_with_internal_code('c_whp_par_1',
                                     'ost kyc webhook error',
                                     GlobalConstant::ErrorCode.invalid_request_parameters,
                                     {}, {}, ''
            )

          when 'Net::HTTPUnprocessableEntity'
            # 422
            error_with_internal_code('c_whp_par_2',
                                     'ost kyc webhook error',
                                     GlobalConstant::ErrorCode.unprocessable_entity,
                                     {}, {}, ''
            )
          when "Net::HTTPUnauthorized"
            # 401
            error_with_internal_code('c_whp_par_3',
                                     'ost kyc webhook authentication failed',
                                     GlobalConstant::ErrorCode.unauthorized_access,
                                     {}, {}, ''
            )

          when "Net::HTTPBadGateway"
            #500
            error_with_internal_code('c_whp_par_4',
                                     'ost kyc webhook bad gateway',
                                     GlobalConstant::ErrorCode.unhandled_exception,
                                     {}, {}, ''
            )
          when "Net::HTTPInternalServerError"
            error_with_internal_code('c_whp_par_5',
                                     'ost kyc webhook bad internal server error',
                                     GlobalConstant::ErrorCode.unhandled_exception,
                                     {}, {}, ''
            )
          when "Net::HTTPForbidden"
            #403
            error_with_internal_code('c_whp_par_6',
                                     'ost kyc webhook forbidden',
                                     GlobalConstant::ErrorCode.forbidden,
                                     {}, {}, ''
            )
          else
            # HTTP error status code (500, 504...)
            error_with_internal_code('c_whp_par_7',
                                     "ost kyc webhook STATUS CODE #{http_response.code.to_i}",
                                     GlobalConstant::ErrorCode.unhandled_exception,
                                     {}, {}, 'ost kyc webhook exception'
            )
        end
      end

      # generate a uniq lock id for each iteration
      #
      # * Author: Aman
      # * Date: 15/10/2018
      # * Reviewed By:
      #
      #  @returns [String] returns a lock id generated unique for each iteration
      #
      def get_lock_id
        "#{@cron_identifier}_#{Time.now.to_f}_#{client_webhook_setting.id}_#{@iteration_count}"
      end

      # get a client webhook setting to be processed based on last processed time
      #
      # * Author: Aman
      # * Date: 15/10/2018
      # * Reviewed By:
      #
      def client_webhook_setting
        fail 'unimplemented method client_webhook_setting'
      end

      # get current timestamp
      #
      # * Author: Aman
      # * Date: 15/10/2018
      # * Reviewed By:
      #
      # @returns [Integer] returns current time in epoch seconds
      #
      def current_timestamp
        Time.now.to_i
      end

    end

  end
end
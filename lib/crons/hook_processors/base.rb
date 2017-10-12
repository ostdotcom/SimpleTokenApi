module Crons

  module HookProcessors

    class Base

      include Util::ResultHelper

      # Initialize
      #
      # * Author: Puneet
      # * Date: 11/11/2017
      # * Reviewed By:
      #
      # @param [Boolean] process_failed boolean tells if this iteration is to retry failed hooks or to process fresh ones
      #
      def initialize(params)

        @process_failed = params[:process_failed]

        @current_timestamp = Time.now.to_i
        @lock_identifier = @current_timestamp

        @data_to_process = []
        @success_responses = {}
        @failed_hook_to_be_retried = {}
        @failed_hook_to_be_ignored = {}

      end

      # public method to process hooks
      #
      # * Author: Puneet
      # * Date: 11/11/2017
      # * Reviewed By:
      #
      def perform
        begin
          fetch_hooks_to_be_processed
          process_hooks
          mark_synced_hooks
        rescue StandardError => se
          @data_to_process.each do |hook|
            hook_id = hook.id
            # Skip if we already know that his hook was processed or failed
            next if @success_responses[hook_id].present? ||
              @failed_hook_to_be_ignored[hook_id].present? ||
              @failed_hook_to_be_retried[hook_id].present?
            @failed_hook_to_be_retried[hook_id] = {
              exception: {message: se.message, trace: se.backtrace}
            }
          end
        ensure
          unlock_failed_hooks
          notify_devs
          success_with_data(processor_response)
        end
      end

      private

      # find if this is an iteration to process failed logs or fresh ones. we default to false
      #
      # * Author: Puneet
      # * Date: 11/11/2017
      # * Reviewed By:
      #
      def retry_failed_hooks?
        @retry_failed ||= (@process_failed.nil? ? false : @process_failed)
      end

      # acquire lock on a batch of records
      #
      # * Author: Puneet
      # * Date: 11/11/2017
      # * Reviewed By:
      #
      def acquire_lock
        retry_failed_hooks? ? acquire_lock_on_failed_hooks : acquire_lock_on_fresh_hooks
      end

      # Fetch records from DB which are to be processed in this iteration
      #
      # * Author: Puneet
      # * Date: 11/11/2017
      # * Reviewed By:
      #
      def fetch_hooks_to_be_processed
        acquire_lock
        fetch_locked_hooks
      end

      # Acquire lock on Failed Hooks which have to be retired
      #
      # * Author: Puneet
      # * Date: 11/11/2017
      # * Reviewed By:
      #
      def acquire_lock_on_failed_hooks
        modal_klass.lock_failed_hooks(@lock_identifier)
      end

      # Acquire lock on Fresh Hooks which have to be executed
      #
      # * Author: Puneet
      # * Date: 11/11/2017
      # * Reviewed By:
      #
      def acquire_lock_on_fresh_hooks
        modal_klass.lock_fresh_hooks(@lock_identifier)
      end

      # query search_hooks table to fetch data for records locked with the given identifier
      #
      # * Author: Puneet
      # * Date: 11/11/2017
      # * Reviewed By:
      #
      def fetch_locked_hooks
        @data_to_process = modal_klass.fetch_locked_hooks(@lock_identifier)
      end

      # method which process hooks and performs required operation
      #
      # * Author: Puneet
      # * Date: 11/11/2017
      # * Reviewed By:
      #
      def process_hooks
        @data_to_process.each do |hook|
          begin
            @hook = hook
            process_hook
          rescue StandardError => se
            @failed_hook_to_be_retried[@hook.id] = {
              exception: {
                message: se.message,
                trace: se.backtrace[0..10]
              }
            }
          end
        end
      end

      # for the hooks which failed, unlock those records so that thet can be reprocessed later
      #
      # * Author: Puneet
      # * Date: 11/11/2017
      # * Reviewed By:
      #
      def unlock_failed_hooks

        @data_to_process.each do |hook|

          failed_hook_to_be_retried = @failed_hook_to_be_retried[hook.id]
          hook.mark_failed_to_be_retried(failed_hook_to_be_retried) if failed_hook_to_be_retried.present?

          failed_hook_to_be_ignored = @failed_hook_to_be_ignored[hook.id]
          hook.mark_failed_to_be_ignored(failed_hook_to_be_ignored) if failed_hook_to_be_ignored.present?

        end

      end

      # return data for logging
      #
      # * Author: Puneet
      # * Date: 11/11/2017
      # * Reviewed By:
      #
      def processor_response
        {
          @lock_identifier => {
            failed_hook_ids_to_be_retried: @failed_hook_to_be_retried.keys,
            failed_hook_ids_to_be_ignored: @failed_hook_to_be_ignored.keys,
            synced_hook_ids: @success_responses.keys
          }
        }
      end

      # modal klass which has data about  hooks
      #
      # * Author: Puneet
      # * Date: 11/11/2017
      # * Reviewed By:
      #
      # @return [Class] : returns a class
      #
      def modal_klass
        fail 'child class to return a model klass here'
      end

      # Process One Hook
      #
      # * Author: Puneet
      # * Date: 11/11/2017
      # * Reviewed By:
      #
      def process_hook
        fail 'child class to implement'
      end

      # after successfully performing task, mark hooks as processed
      #
      # * Author: Puneet
      # * Date: 11/11/2017
      # * Reviewed By:
      #
      def mark_synced_hooks
        fail 'child class to implement'
      end

      # Notify Devs in case of Error
      #
      # * Author: Puneet
      # * Date: 11/11/2017
      # * Reviewed By:
      #
      def notify_devs
        fail 'child class to implement'
      end

    end

  end

end
module Ddb
  module Api
    class BatchWrite < Base
      def initialize(params)
        super
      end

      def perform
        batch_write_operation
      rescue Aws::DynamoDB::Errors::ProvisionedThroughputExceededException => e
        Rails.logger.info {'Ddb::Api::BatchWrite::Sleeping..Retrying..'}
        #increase_read_capacity
        if @retry_count >= @current_retry_count
          return error_with_identifier('ddb_provision_throughput_exception', '', '',
                                       'Throughput exception while deleting record', {})
        else
          sleep(@retry_after_duration)
          @current_retry_count += 1
          @retry_after_duration += @retry_time_incrementer
          retry
        end

      end


      def batch_write_operation
        batch_write_resp = ddb_client.batch_write_item @params
        if batch_write_resp.unprocessed_items.present? && @retry_count < @current_retry_count
          @params = batch_write_resp.unprocessed_items
          sleep(@retry_after_duration)
          @current_retry_count += 1
          @retry_after_duration += @retry_time_incrementer
          batch_write_operation
        else
          return error_with_identifier('batch_write_retry_count_exceeded', '',
                                       [], 'Batch write operation failed',
                                       batch_write_resp.unprocessed_items) if batch_write_resp.unprocessed_items.present?
          success
        end


      end


    end
  end
end
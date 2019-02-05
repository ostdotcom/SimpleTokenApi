module Ddb
  module Api
    class BatchWrite < Base
      def initialize(params)
        super
      end

      # perform batch write
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      def perform
        with_error_handling {batch_write_operation}
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

      # batch write api call with retry mechanism
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # # @return [Result::Base]
      #
      def batch_write_operation
        batch_write_resp = ddb_client.batch_write_item @params
        if batch_write_resp.unprocessed_items.present? && @retry_count < @current_retry_count
          @params = batch_write_resp.unprocessed_items
          sleep(@retry_after_duration)
          @current_retry_count += 1
          @retry_after_duration += @retry_time_incrementer
          batch_write_operation
        else
          success_with_data({data: batch_write_resp.unprocessed_items})
        end
      end

    end
  end
end
module Ddb
  module Api
    class BatchWrite < Api::Base
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
      rescue StandardError => e
        return error_with_identifier('ddb_standard_error', 'standard_error',
                                     [], e.message, {})

      rescue Exception => e
        return exception_with_data(
            e,
            'swr_d_a_bw_p_1',
            'exception in DDB: ' + e.message,
            'Something went wrong.',
            GlobalConstant::ErrorAction.default,
            {}
        )


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

        if batch_write_resp.unprocessed_items.blank?
          return success_with_data(data: batch_write_resp)
        elsif @retry_count < @current_retry_count
          @params = batch_write_resp.unprocessed_items
          sleep(@retry_after_duration)
          @current_retry_count += 1
          @retry_after_duration += @retry_time_incrementer
          return batch_write_operation
        else
          return error_with_data('ddb_bwo_1',
                                 "Batch write operation has been failed",
                                 "Batch write operation has been failed",
                                 GlobalConstant::ErrorAction.default,
                                 {data: batch_write_resp.unprocessed_items})
        end
      end

    end
  end
end
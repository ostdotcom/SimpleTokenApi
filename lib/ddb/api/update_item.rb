module Ddb
  module Api
    class UpdateItem < Base
      def initialize(params)
        super
      end

      def perform
        with_error_handling {ddb_client.update_item @params}
      rescue Aws::DynamoDB::Errors::ProvisionedThroughputExceededException => e
        Rails.logger.info {'Ddb::Api::UpdateItem::Sleeping..Retrying..'}
        #increase_read_capacity
        if @retry_count >= @current_retry_count
          return error_with_identifier('', 'ddb_provision_throughput_exception',
                                       '', 'Throughput exception while updating record', {})
        else
          sleep( @retry_after_duration )
          @current_retry_count += 1
          @retry_after_duration += @retry_time_incrementer
          retry
        end
      end
    end
  end
end
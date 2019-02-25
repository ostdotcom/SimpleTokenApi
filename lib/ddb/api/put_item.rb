module Ddb
  module Api
    class PutItem < Api::Base

      def initialize(params)
        super
      end

      # put item  api call with retry mechanism
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform
        with_error_handling {ddb_client.put_item @params}
      rescue Aws::DynamoDB::Errors::ProvisionedThroughputExceededException => e
        Rails.logger.info {'Ddb::Api::PutItem::Sleeping..Retrying..'}
        #increase_read_capacity
        if @retry_count >= @current_retry_count
          # todo:ddb: - api error code
          return error_with_identifier('', 'd_a_pi_p_1',
                                       '', 'Throughput exception while put record', {})
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
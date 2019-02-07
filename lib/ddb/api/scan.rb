module Ddb
  module Api
    class Scan < Api::Base
      def initialize(params)
        super
      end


      # scan api call with retry mechanism
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform
        with_error_handling {ddb_client.scan @params}
      rescue Aws::DynamoDB::Errors::ProvisionedThroughputExceededException => e
        Rails.logger.info {'Ddb::Api::Scan::Sleeping..Retrying..'}
        #increase_read_capacity
        if @retry_count >= @current_retry_count
          return error_with_identifier('', 'ddb_provision_throughput_exception',
                                       '', 'Throughput exception while scanning record', {})
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
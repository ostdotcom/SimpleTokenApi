module Ddb
  module Api
    class Base

      RETRY_COUNT = 10
      RETRY_TIME_INCREMENTER = 0.5 # in secs
      INITIAL_RETRY_AFTER = 3 # in secs

      include Util::ResultHelper

      def initialize(params)
        @params = params[:params]
        @retry_count = params[:retry_count] || RETRY_COUNT
        @current_retry_count = 0
        @retry_time_incrementer = RETRY_TIME_INCREMENTER
        @retry_after_duration = INITIAL_RETRY_AFTER
      end

      def ddb_client
        @ddb_client ||= Ddb.client
      end


      def with_error_handling
        success_with_data(data: yield)

      rescue => e
        handle_error(e)
      end


      def handle_error(e)
        case e
        when Aws::DynamoDB::Errors::ProvisionedThroughputExceededException
          raise e
          # Increase throughput
        when StandardError
          #
        else
          #
        end
      end
    end
  end
end
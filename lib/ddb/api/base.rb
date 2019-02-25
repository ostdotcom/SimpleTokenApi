module Ddb
  module Api
    class Base

      MAX_RETRY_COUNT = 10
      RETRY_TIME_INCREMENTER = 0.5 # in secs
      INITIAL_RETRY_AFTER = 3 # in secs

      include Util::ResultHelper

      def initialize(params)
        @params = params[:params]
        @retry_count = MAX_RETRY_COUNT
        @current_retry_count = 0
        @retry_time_incrementer = RETRY_TIME_INCREMENTER
        @retry_after_duration = INITIAL_RETRY_AFTER
      end


      # get dynamo db client
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      def ddb_client
        @ddb_client ||= Ddb.client
      end

      # error handling wrapper for ddb requests
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      def with_error_handling
        success_with_data(data: yield)

      rescue => e
        handle_error(e)
      end

      # handling exception as per cases
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      # @return [Result::Base || Exception ]
      #
      def handle_error(e)
        case e
          when Aws::DynamoDB::Errors::ProvisionedThroughputExceededException
            #  todo:ddb -  common error handling for ProvisionedThroughputExceededException
            raise e
          when StandardError
            return error_with_identifier('ddb_standard_error', 'standard_error',
                                         [], e.message, {})
          else
            return exception_with_data(
                e,
                'swr_a_b_he_1',
                'exception in DDB: ' + e.message,
                'Something went wrong.',
                GlobalConstant::ErrorAction.default,
                {}
            )
        end
      end
    end
  end
end
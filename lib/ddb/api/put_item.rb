module Ddb
  module Api
    class PutItem < Base

      def initialize(params)
        super
      end

      def perform

        with_error_handling    {ddb_client.put_item @params}
        #ddb_client.put_item @params
      rescue Aws::DynamoDB::Errors::ProvisionedThroughputExceededException => e
        Rails.logger.info{'Ddb::Api::PutItem::Sleeping..Retrying..'}
        # increase_read_capacity
        if @retry_count >= @current_retry_count
          return error_with_identifier('','','','',{})
        else
          sleep(3)
          @current_retry_count += 1
          retry
        end



      end


    end
  end
end
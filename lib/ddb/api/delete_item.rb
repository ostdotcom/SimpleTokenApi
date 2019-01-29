module Ddb
  module Api
    class DeleteItem < Base
      def initialize(params)
        super
      end

      def perform
        with_error_handling {ddb_client.delete_item @params}
      rescue Aws::DynamoDB::Errors::ProvisionedThroughputExceededException => e
        Rails.logger.info{'Ddb::Api::GetItem::Sleeping..Retrying..'}
        increase_read_capacity
        sleep(3)
        retry
      end


    end
  end
end
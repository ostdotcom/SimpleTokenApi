module Ddb
  module Api
    class Base

      include Util::ResultHelper

      def initialize(params)
        @params = params
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
          # aassa
          puts "How i m here"
        else
          puts "How i m here2"
          # aassa
        end
      end
    end
  end
end
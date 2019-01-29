module Ddb
  module Api
    class BatchWrite < Base
      def initialize(params)
        super
      end

      def perform
        ddb_client.batch_write_item @params
      end


    end
  end
end
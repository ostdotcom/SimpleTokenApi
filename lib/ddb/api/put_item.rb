module Ddb
  module Api
    class PutItem < Base
      def initialize(params)
        super
      end

      def perform
        ddb_client.put_item @params
      end


    end
  end
end
module Ddb
  module Api
    class Query < Base
      def initialize(params)
        super
      end

      def perform
        ddb_client.query @params
      end


    end
  end
end
module Ddb
  module Api
    class Scan < Base
      def initialize(params)
        super
      end

      def perform
        ddb_client.scan @params
      end


    end
  end
end
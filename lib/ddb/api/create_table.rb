module Ddb
  module Api
    class CreateTable < Base
      def initialize(params)
        super
      end

      def perform
        ddb_client.create_table @params
      end

    end
  end
end


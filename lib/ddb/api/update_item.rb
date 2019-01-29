module Ddb
  module Api
    class UpdateItem < Base
      def initialize(params)
        super
      end

      def perform
        ddb_client.update_item @params
      end


    end
  end
end
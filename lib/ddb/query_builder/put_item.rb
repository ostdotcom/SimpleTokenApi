module Ddb
  module QueryBuilder
    class PutItem < Base
      def initialize(params)
        super



      end

      def perform

        r = validate
        return r unless r.success?

        success_with_data ({
            item: @params[:item],
            table_name: @table_info[:name]
        })

      end

      def validate
        r = validate_for_keys(:partition_keys)
        return r unless r.success?

        r = validate_for_keys(:sort_keys)
        return r unless r.success?

        success


      end

      def input_hash_with_long_name
        @params[:item]
      end

      def list_of_keys
        @params[:item].keys
      end



    end
  end
end
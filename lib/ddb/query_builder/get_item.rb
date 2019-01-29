module Ddb
  module QueryBuilder
    class GetItem < Base
      def initialize(params)
        super

      end

      def perform

        r = validate
        return r unless r.success?

        success_with_data({
            key: get_key,
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

      def list_of_keys
        @params[:key].keys
      end



    end
  end
end
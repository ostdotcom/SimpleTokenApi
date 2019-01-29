module Ddb
  module QueryBuilder
    class DeleteItem < Base
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

      def get_key

        hash = @params[:key]

        ddb_partition_key = get_short_key_name(@table_info[:partition_keys])

        ddb_sort_key = get_short_key_name(@table_info[:sort_keys])

        hash.reject! {|k| ! [ddb_partition_key, ddb_sort_key].include?(k)}
      end



    end
  end
end
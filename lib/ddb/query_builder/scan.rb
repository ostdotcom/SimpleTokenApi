module Ddb
  module QueryBuilder
    class Scan < Base
      def initialize(params)
        super

      end

      def perform

        r = validate
        return r unless r.success?

        success_with_data({
                              filter_expression: filter_expression,
                              table_name: @table_info[:name],
                              expression_attribute_values:
                                  @expression_attribute_values.present? ? @expression_attribute_values : nil,
                              exclusive_start_key: @params[:exclusive_start_key],
                              page_size: @params[:page_size]
                          }.delete_if {|_, v| v.nil?}
        )

      end

      def validate
        success
      end


      def get_key

        hash = @params[:key]

        ddb_partition_key = get_short_key_name(@table_info[:partition_keys])

        ddb_sort_key = get_short_key_name(@table_info[:sort_keys])

        hash.reject! {|k| ![ddb_partition_key, ddb_sort_key].include?(k)}
      end


    end
  end
end


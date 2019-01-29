module Ddb
  module QueryBuilder
    class Query < Base
      def initialize(params)
        super


      end

      def validate

        r = validate_for_keys(:partition_keys)
        return r unless r.success?

        success
      end

      def list_of_keys
        primary_keys = []
        @params[:key_conditions].each do |condition|
          primary_keys += condition[:attribute].keys
        end
        primary_keys
      end

      def perform
        r = validate

        return r unless r.success?

        filter_key_conditions

        success_with_data(
            {
                key_condition_expression: key_condition_expression,
                table_name: @table_info[:name],
                filter_expression: filter_expression,
                exclusive_start_key: @params[:exclusive_start_key],
                page_size: @params[:page_size],
                expression_attribute_values: @expression_attribute_values
            }.delete_if {|_, v| v.nil?}
        )
      end

      def filter_key_conditions

        ddb_partition_key = get_short_key_name(@table_info[:partition_keys])

        ddb_sort_key = get_short_key_name(@table_info[:sort_keys])

        @params[:key_conditions].each_with_index do |value, index|
          @params[:key_conditions][index][:attribute] = value[:attribute].reject! {|k|
            ! [ddb_partition_key, ddb_sort_key].include?(k)}
        end
      end

      def key_condition_expression
        expression = []
        get_key_hash.each do |key, val|
          expression << " #{key.to_s}#{val[:operator]} :#{key.to_s}"
          @expression_attribute_values[":#{key.to_s}"] = val[:value]
        end

        puts "key condition expression #{expression.join(" AND")}"
        puts "dddssss #{@expression_attribute_values}"

        expression.join(" AND")
      end

      def get_key_hash
        key_hash = {}
        @params[:key_conditions].each do |condition|
          key_hash[condition[:attribute].keys[0]] = {value: condition[:attribute].values[0],
                                                     operator: condition[:operator]} if condition[:attribute].keys.present?
        end
        key_hash
      end

    end
  end
end
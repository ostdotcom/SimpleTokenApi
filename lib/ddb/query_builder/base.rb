module Ddb
  module QueryBuilder
    class Base

      include Util::ResultHelper

      def initialize(params)
        @params = params[:params]
        @table_info = params[:table_info]
        @delimiter = @table_info[:delimiter]
        @expression_attribute_values = {}
      end

      def validate_for_keys(key_type)
        short_key = get_short_key_name(@table_info[key_type])


        return error_with_identifier('',
                                     '',
                                     '',
                                     '',
                                     {}
        ) if (short_key.present? && list_of_keys.exclude?(short_key))
        success
      end

      def list_of_keys
        fail "child class has to implement this"
      end

      def input_hash_with_long_name
        fail "child class has to implement this"
      end

      def get_short_key_name(condition)
        @table_info[:merged_columns].
            select {|_, v| v[:keys].sort == condition.sort}.keys.first
      end


      def filter_expression
        expression = []
        conditions = @params[:filter_conditions] && @params[:filter_conditions][:conditions]
        puts "dnnnnnn #{conditions}"
        return nil if conditions.blank?
        conditions.each do |condition|
          operator = condition[:operator]
          condition[:attribute].each do |attr_key, attr_val|
            puts "----94394394 #{attr_val} #{attr_key}"
            expression << " #{attr_key} #{operator} :#{attr_key}"
            @expression_attribute_values[":#{attr_key.to_s}"] = attr_val
          end
        end
        expression.join(" #{@params[:filter_conditions][:logical_operator]}")

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

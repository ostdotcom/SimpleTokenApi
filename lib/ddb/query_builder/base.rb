module Ddb
  module QueryBuilder
    class Base

      include Util::ResultHelper

      def initialize(params)

        @params = params[:params]
        @table_info = params[:table_info]
        @delimiter = @table_info[:delimiter]
        @expression_attribute_values = {}
        @expression_attribute_names = {}
      end

      def validate_primary_key
        key = [@table_info[:partition_key], @table_info[:sort_key]].compact

        return success if (@key_hash.keys - key).blank? && (key - @key_hash.keys).blank?
        error_with_identifier('invalid_keys',
                              '',
                              '',
                              '',
                              {}
        )
      end

      def list_of_keys
        fail "child class has to implement this"
      end

      def get_short_key_name(condition)
        @table_info[:merged_columns].
            select {|_, v| v[:keys].sort == condition.sort}.keys.first
      end


      def condition_expression(conditions, logical_operator)
        expression = []
        conditions.each do |condition|
          key = condition[:attribute].keys[0].to_s
          val = condition[:attribute].values[0]
          expression << "##{key}_name #{condition[:operator]} :#{key}_val"
          @expression_attribute_values[":#{key}_val"] = val
          @expression_attribute_names["##{key}_name"] = key
        end
        expression.join(" #{logical_operator} ")
      end


      def get_formatted_item_hash(param_key)

        hash = {}
        @params[param_key].each do |val|
          expression = val[:attribute]
          hash[expression.keys[0]] = expression.values[0]
        end

        hash.deep_symbolize_keys
      end

    end


  end
end

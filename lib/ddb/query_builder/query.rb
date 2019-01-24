module Ddb
  module QueryBuilder
    class Query < Base
      def initialize(params, table_options)
        super

      end

      def perform
         {
            key_condition_expression: key_condition_expression,
            table_name: @table_options[:name] ,
            expression_attribute_values: @expression_attribute_values
        }

      end

      def key_condition_expression
        key_hash = get_key_hash

        expression = ''
        key_hash.each do |key, val|
          prefix = expression.blank? ? "" : "AND"
          expression += " #{prefix} #{key.to_s}#{val[:operator]} :#{key.to_s}"
          @expression_attribute_values[":#{key.to_s}"] = val[:value]
        end
        expression
      end
    end
  end
end
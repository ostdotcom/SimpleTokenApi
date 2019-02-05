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

      # validate primary key (partition key + sort key)
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      def validate_primary_key
        puts "@key_hash #{@key_hash} @table_info[:sort_key] #{@table_info[:sort_key]} @table_info[:partition_key] #{@table_info[:partition_key]}"


        key = [@table_info[:partition_key], @table_info[:sort_key]].compact

        return success if (@key_hash.keys - key).blank? && (key - @key_hash.keys).blank?
        error_with_identifier('invalid_keys',
                              '',
                              '',
                              '',
                              {}
        )
      end

      # returns backend name of key list(multiple keys can be mapped with single backend name)
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      # @param key_list [Array] (mandatory)
      # @return [String]
      #
      def get_short_key_name(key_list)
        @table_info[:merged_columns].
            select {|_, v| v[:keys].sort == key_list.sort}.keys.first
      end

      # create condition expression string from input conditions, all conditions are joined by given logical operator
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      # @param conditions [Array] (mandatory)
      # @param logical_operator [String] (mandatory)
      # @return [String]
      #
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

      # convert input item format to ddb item format
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      # @param param_key [symbol] (mandatory)
      # @return [Hash]
      #
      def get_formatted_item_hash(param_list)

        hash = {}
        param_list.each do |val|
          expression = val[:attribute]
          hash[expression.keys[0]] = expression.values[0]
        end

        hash.deep_symbolize_keys
      end

    end
  end
end

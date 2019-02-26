module Ddb
  module QueryBuilder
    class Base

      include Util::ResultHelper

      def initialize(params)
        @params = params[:params]
        @expression_names_count = 0
        @expression_values_count = 0
        @table_info = params[:table_info]
        @delimiter = @table_info[:delimiter]
        @expression_attribute_values = {}
        @expression_attribute_names = {}
        # move to gc
        @allowed_logical_operators = ["AND", "OR"]
        @allowed_operator_values = ["=", "<", ">", "<>"]
      end

      # create condition expression string from input conditions, all conditions are joined by given logical operator
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @param conditions [Array] (mandatory)
      # @param logical_operator [String] (mandatory)
      #
      # @return [Result::Base]
      #
      def condition_expression(conditions, separator)
        return error_with_identifier("operator_not_allowed",
                                     "") unless @allowed_logical_operators.include?(separator)

        expression = []
        conditions.each do |condition|
          return error_with_identifier("operator_not_allowed", "") if condition[:operator].present? &&
              !@allowed_operator_values.include?(condition[:operator])

          key = condition[:attribute].keys[0].to_s
          val = condition[:attribute].values[0]
          name_alias = get_name_alias(key)
          value_alias = get_value_alias(val)
          expression << "#{name_alias} #{condition[:operator]} #{value_alias}"
        end
        success_with_data(data: expression.join(" #{separator} "))
      end

      def create_expression_for_list(list, separator)
        expression = []
        list.each do |ele|
          name_alias = get_name_alias(ele)
          expression << name_alias
        end
        expression.join(" #{separator} ")
      end

      def get_projection_expression
        projection_expr = nil
        if @params[:projection_expression].present?
          projection_expr = create_expression_for_list(@params[:projection_expression], ", ")
        end
        projection_expr
      end

      # validate primary key (partition key + sort key)
      #
      #  @params []
      #
      # * Author: mayur
      # * Date: 01/02/2019
      #
      # * Reviewed By:
      #
      def validate
        if @params[:key].present? || @params[:item].present?
          validate_primary_key
        end
      end

      def validate_primary_key
        key = [@table_info[:partition_key], @table_info[:sort_key]].compact
        if @params[:key].present?
          return success if (key_hash(@params[:key]).keys - key).blank? && (key - key_hash(@params[:key]).keys).blank?
        elsif @params[:item].present?
          return success if (key - key_hash(@params[:item]).keys).blank?
        end





        error_with_identifier('invalid_keys',
                              '',
                              '',
                              '',
                              {}
        )



      end

      # returns primary key hash
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @return [Hash]
      #
      def key_hash(params)
        @key_hash ||= get_formatted_item_hash(params)
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

      def get_name_alias(key)
        key = key.to_s
        return @expression_attribute_names[key] if @expression_attribute_names[key].present?

        @expression_names_count += 1
        k = "#n_#{@expression_names_count}"
        @expression_attribute_names[key] = k
        k
      end

      def get_value_alias(value)
        if @expression_attribute_values.values.include?(value)
          @expression_attribute_values.key(value)
        else
          @expression_values_count += 1
          v = ":v_#{@expression_values_count}"
          @expression_attribute_values["#{value_alias}"] = v
          v
        end
      end

      def expression_attribute_names_query
        @expression_attribute_names.present? ? @expression_attribute_names.invert : nil
      end

      def expression_attribute_values_query
        @expression_attribute_values.present? ? @expression_attribute_values : nil
      end

    end
  end
end

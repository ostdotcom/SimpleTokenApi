module Ddb
  module QueryBuilder
    class UpdateItem < QueryBuilder::Base
      def initialize(params)
        super
      end

      # returns update item query
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform

        r = validate
        return r unless r.success?

        c_u_expression = create_update_expression

        success_with_data ({
            key: @key_hash,
            table_name: @table_info[:name],
            update_expression: c_u_expression.present? ? c_u_expression : nil,
            return_values: @params[:return_values],
            return_item_collection_metrics: @params[:return_item_collection_metrics],
            return_consumed_capacity: @params[:return_consumed_capacity],
            expression_attribute_values: expression_attribute_values_query,
            expression_attribute_names: expression_attribute_names_query
        }.delete_if {|_, v| v.nil?}
                          )
      end

      # create update expression
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def create_update_expression
        set_expr_str, add_expr_str, remove_expr_str = "", "", ""

        if @params[:set].present?
          r = create_expression(@params[:set], " = ", ', ')
          return r unless r.success?
          set_expr_str = "SET #{r.data[:data]}"
        end

        if @params[:add].present?
          r = create_expression(@params[:add], "  ", ', ')
          return r unless r.success?
          add_expr_str = "ADD #{r.data[:data]}"
        end

        if @params[:remove].present?
          remove_expr_str = create_expression_for_list(@params[:remove], " ")
          remove_expr_str = "REMOVE #{remove_expr_str}"
        end
        [set_expr_str, add_expr_str, remove_expr_str].reject(&:blank?).join(' ')
      end


      def create_expression(conditions, operator, separator)
        expression = []
        conditions.each do |condition|
          key = condition[:attribute].keys[0].to_s
          val = condition[:attribute].values[0]
          name_alias = get_name_alias(key)
          value_alias = get_value_alias(val)
          expression << "#{name_alias} #{operator} #{value_alias}"
        end
        success_with_data(data: expression.join(" #{separator} "))
      end
    end

  end
end


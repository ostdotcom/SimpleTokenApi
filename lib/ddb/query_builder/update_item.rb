module Ddb
  module QueryBuilder
    class UpdateItem < Base
      def initialize(params)
        super


      end

      def perform

        @key_hash = get_formatted_item_hash(:key)

        r = validate_primary_key
        return r unless r.success?
        success_with_data ({
            key: @key_hash,
            table_name: @table_info[:name],
            update_expression: create_update_expression,
            expression_attribute_values: @expression_attribute_values.present? ? @expression_attribute_values : nil,
            expression_attribute_names: @expression_attribute_names.present? ? @expression_attribute_names : nil,
            return_values: @params[:return_values],
            return_item_collection_metrics: @params[:return_item_collection_metrics],
            return_consumed_capacity: @params[:return_consumed_capacity]
        }.delete_if {|_, v| v.nil?}
                          )
      end


      def create_update_expression
        set_expression, add_expression = [], []
        @params[:set].each do |v|
          set_expression << "##{v[:attribute].keys[0]}_name = :#{v[:attribute].keys[0]}_value"
          @expression_attribute_values[":#{v[:attribute].keys[0]}_value"] = v[:attribute].values[0]
          @expression_attribute_names["##{v[:attribute].keys[0]}_name"] = v[:attribute].keys[0]
        end if @params[:set].present?
        set_expr_str = set_expression.present? ? "SET #{set_expression.join(', ')}" : ''
        @params[:add].each do |v|
          add_expression << "##{v[:attribute].keys[0]}_name :#{v[:attribute].keys[0]}_value"
          @expression_attribute_values[":#{v[:attribute].keys[0]}_value"] = v[:attribute].values[0]
          @expression_attribute_names["##{v[:attribute].keys[0]}_name"] = v[:attribute].keys[0]
        end if @params[:add].present?
        add_expr_str = add_expression.present? ? "ADD #{add_expression.join(', ')}" : ''

        remove_expr_str = @params[:remove].present? ? "REMOVE #{@params[:remove].join(' ')}" : ''

        [set_expr_str, add_expr_str, remove_expr_str].join(' ')
      end
    end

  end
end


module Ddb
  module QueryBuilder
    class UpdateItem < Base
      def initialize(params)
        super



      end

      def perform

        r = validate
        return r unless r.success?
        puts "---------- #{create_update_expression}"
        puts "-----$---- #{@expression_attribute_values}"
        puts "table name #{@table_info[:name]}"
        success_with_data ({
            key: get_key,
            table_name: @table_info[:name],
            update_expression: create_update_expression,
            expression_attribute_values: @expression_attribute_values
        })
      end

      def validate
        r = validate_for_keys(:partition_keys)
        return r unless r.success?

        r = validate_for_keys(:sort_keys)
        return r unless r.success?

        success


      end

      def create_update_expression
        set_expression, add_expression = [], []
        @params[:set].each do |v|
          set_expression << "#{v[:attribute].keys[0]} = :#{v[:attribute].keys[0]}"
          @expression_attribute_values[":#{v[:attribute].keys[0]}"] = v[:attribute].values[0]
        end
        set_expr_str = set_expression.present? ? "SET #{set_expression.join(', ')}": ''
        @params[:add].each do |v|
          add_expression << "#{v[:attribute].keys[0]} :#{v[:attribute].keys[0]}"
          puts "----------->>>>>>>#{v[:attribute].keys[0]}>>>>>>>>>>>>> #{v[:attribute].values[0]} ====== #{v[:attribute].values[0].class}"
          @expression_attribute_values[":#{v[:attribute].keys[0]}"] = v[:attribute].values[0]
        end
        add_expr_str = add_expression.present? ? "ADD #{add_expression.join(', ')}": ''
        remove_expr_str = @params[:remove].present? ? "REMOVE #{@params[:remove].join(' ')}": ''
        [set_expr_str, add_expr_str, remove_expr_str].join(' ')



      end





      def input_hash_with_long_name
        @params[:item]
      end

      def list_of_keys
        puts "@paramas #{@params}"
        @params[:key].keys
      end



    end
  end
end
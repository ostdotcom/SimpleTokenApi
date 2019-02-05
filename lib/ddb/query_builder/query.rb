module Ddb
  module QueryBuilder
    class Query < Base
      def initialize(params)
        super

      end

      # returns query for ddb query operation
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform

        @index_name = @params[:index_name]

        r = validate

        return r unless r.success?

        filter_expn = condition_expression(@params[:filter_conditions][:conditions],
                                           @params[:filter_conditions][:logical_operator]) if @params[:filter_conditions].present?
        success_with_data(
            {
                key_condition_expression: condition_expression(@params[:key_conditions], 'AND'),
                table_name: @table_info[:name],
                filter_expression: filter_expn,
                exclusive_start_key: @params[:exclusive_start_key],
                limit: @params[:limit],
                expression_attribute_values: @expression_attribute_values,
                expression_attribute_names: @expression_attribute_names,
                index_name: @params[:index_name],
                return_consumed_capacity: @params[:return_consumed_capacity],
                projection_expression: @params[:projection_expression].present? ?
                                           @params[:projection_expression].join(", ") : nil,
                consistent_read: @params[:consistent_read]

            }.delete_if {|_, v| v.nil?}
        )
      end

      # validate params for query operation
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def validate

        if @index_name.present?
          return success if ([@table_info[:indexes][@index_name][:partition_key]] - list_of_keys).blank?
        else
          return success if ([@table_info[:partition_key]] - list_of_keys).blank?
        end
        error_with_identifier('invalid_keys',
                              '')

      end


      # return list of keys
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def list_of_keys
        primary_keys = []

        @params[:key_conditions].each do |condition|
          condition.deep_symbolize_keys!
          primary_keys += condition[:attribute].keys
        end
        primary_keys
      end



    end
  end
end
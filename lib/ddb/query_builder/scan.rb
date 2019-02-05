module Ddb
  module QueryBuilder
    class Scan < QueryBuilder::Base
      def initialize(params)
        super
      end

      # returns scan query
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform
        filter_expn = condition_expression(@params[:filter_conditions][:conditions],
                      @params[:filter_conditions][:logical_operator] ) if @params[:filter_conditions].present?

        success_with_data({
                              filter_expression: filter_expn,
                              table_name: @table_info[:name],
                              expression_attribute_values: @expression_attribute_values.present? ? @expression_attribute_values : nil,
                              expression_attribute_names: @expression_attribute_names.present? ? @expression_attribute_names : nil,
                              exclusive_start_key: @params[:exclusive_start_key],
                              limit: @params[:limit],
                              index_name: @params[:index_name],
                              consistent_read: @params[:consistent_read],
                              return_consumed_capacity: @params[:return_consumed_capacity],
                              projection_expression: @params[:projection_expression].present? ?
                                                         @params[:projection_expression].join(", ") : nil,
                          }.delete_if {|_, v| v.nil?}
        )
      end

    end
  end
end


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
        filter_expn = nil
        if @params[:filter_conditions].present?
          filter_expn = condition_expression(@params[:filter_conditions][:conditions],
                      @params[:filter_conditions][:logical_operator] )
          return filter_expn unless filter_expn.success?
          filter_expn = filter_expn.data[:data]
        end

        success_with_data({
                              filter_expression: filter_expn,
                              table_name: @table_info[:name],
                              expression_attribute_values: expression_attribute_values_query,
                              expression_attribute_names: expression_attribute_names_query,
                              exclusive_start_key: @params[:exclusive_start_key],
                              limit: @params[:limit],
                              index_name: @params[:index_name],
                              consistent_read: @params[:consistent_read],
                              return_consumed_capacity: @params[:return_consumed_capacity],
                              projection_expression: get_projection_expression ,
                          }.delete_if {|_, v| v.nil?}
        )
      end

    end
  end
end


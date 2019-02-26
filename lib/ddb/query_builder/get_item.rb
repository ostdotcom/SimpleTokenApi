module Ddb
  module QueryBuilder
    class GetItem < QueryBuilder::Base


      def initialize(params)
        super
      end

      # returns get item query as per ddb format
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
        success_with_data({
                              key: @key_hash,
                              table_name: @table_info[:name],
                              projection_expression: get_projection_expression,
                              consistent_read: @params[:consistent_read],
                              return_consumed_capacity: @params[:return_consumed_capacity]
                          }.delete_if {|_, v| v.nil?})

      end
    end
  end
end
module Ddb
  module QueryBuilder
    class PutItem < QueryBuilder::Base
      def initialize(params)
        super
      end

      # returns put item query as per ddb format
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

        success_with_data (
                              {
                                  item: @key_hash,
                                  table_name: @table_info[:name],
                                  return_values: @params[:return_values],
                                  return_consumed_capacity: @params[:return_consumed_capacity],
                                  return_item_collection_metrics: @params[:return_item_collection_metrics]
                              }.delete_if {|_, v| v.nil?
                              }
                          )

      end

    end
  end
end
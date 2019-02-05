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
        @key_hash = get_formatted_item_hash(@params[:item])

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


      def validate
        key = [@table_info[:partition_key], @table_info[:sort_key]].compact

        return success if (key - @key_hash.keys).blank?
        error_with_identifier('invalid_keys',
                              '',

        )
      end
    end
  end
end
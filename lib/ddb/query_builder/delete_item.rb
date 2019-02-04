module Ddb
  module QueryBuilder
    class DeleteItem < Base
      def initialize(params)
        super

      end

      # returns delete query as per ddb format
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform

        @key_hash = get_formatted_item_hash(@params[:key])

        r = validate_primary_key
        return r unless r.success?
        p = {
            key: @key_hash,
            table_name: @table_info[:name],
            return_values: @params[:return_values]
        }
        success_with_data({
                              key: @key_hash,
                              table_name: @table_info[:name],
                              return_values: @params[:return_values],
                              return_item_collection_metrics: @params[:return_item_collection_metrics],
                              return_consumed_capacity: @params[:return_consumed_capacity],
                          }.delete_if {|_, v| v.nil?}
        )

      end

    end
  end
end
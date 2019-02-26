module Ddb
  module QueryBuilder
    class BatchWrite < QueryBuilder::Base
      def initialize(params)
        super
        @key = [@table_info[:partition_key], @table_info[:sort_key]].compact
      end


      # returns batch write query as per ddb format
      #
      # * Author: mayur
      # * Date: 01/02/2019
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform
        # validations
        list = []
        @params[:items].each do |item|
          r = validate_and_format(item)
          return r unless r.success?
          list << {
              put_request: {
                  item: r.data[:data]
              }
          }
        end
        success_with_data ({
            request_items: {
                "#{@table_info[:name]}" => list
            }
        })
      end


      def validate_and_format(item)
        item = get_formatted_item_hash(item)
        return success_with_data(data: item) if (@key - item.keys).blank?
        error_with_identifier("invalid_params", "")
      end
    end
  end
end
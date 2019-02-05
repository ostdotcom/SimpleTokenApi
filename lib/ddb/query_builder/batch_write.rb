module Ddb
  module QueryBuilder
    class BatchWrite < Base
      def initialize(params)
        super
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
        list = []
        @params[:items].each do |item|

          list << {
              put_request: {
                  item: get_formatted_item_hash(item)
              }
          }

        end
        success_with_data ({
            request_items: {
                "#{@table_info[:name]}" => list
            }
        })

      end
    end
  end
end
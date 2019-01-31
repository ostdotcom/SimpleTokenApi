module Ddb
  module QueryBuilder
    class BatchWrite < Base
      def initialize(params)
        super
      end

      def perform
        list = []
        @params[:items].each do | item |

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


      def get_formatted_item_hash(list)
        hash = {}
        list.each do |val|
          expression = val[:attribute]
          hash[expression.keys[0]] = expression.values[0]
        end

        hash.deep_symbolize_keys
      end



    end
  end
end
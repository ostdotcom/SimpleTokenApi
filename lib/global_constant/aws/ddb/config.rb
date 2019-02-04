module GlobalConstant
  module Aws
    module Ddb
      class Config
        class << self


          # hash specifying ddb operations and parameters required/those can be used for these operations
          def allowed_params
            {
                query: {
                    mandatory: [:key_conditions],
                    optional: [:filter_conditions, :consistent_read, :exclusive_start_key,
                               :return_consumed_capacity, :limit, :projection_expression, :index_name]
                },
                delete_item: {
                    mandatory: [:key],
                    optional: [:return_item_collection_metrics, :return_consumed_capacity, :return_values]
                },
                get_item: {
                    mandatory: [:key],
                    optional: [:projection_expression, :consistent_read, :return_consumed_capacity]
                },
                put_item: {
                    mandatory: [:item],
                    optional: [:return_item_collection_metrics, :return_consumed_capacity, :return_values]
                },
                scan: {
                    mandatory: [],
                    optional: [:filter_conditions, :index_name, :consistent_read, :exclusive_start_key,
                               :return_consumed_capacity, :limit, :projection_expression]
                },
                update_item: {
                    mandatory: [:key],
                    optional: [:set, :add, :remove, :return_consumed_capacity, :return_item_collection_metrics, :return_values]
                },

                batch_write: {
                    mandatory: [:items],
                    optional: []
                }
            }
          end

        end
      end
    end
  end
end
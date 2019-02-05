module GlobalConstant
  module Aws
    module Ddb
      class Base
        class << self


          # simple attributes is false

          # eg for: exclusive_start_key
          #

          # use_column_mapping: if true: use full_name, supports merge columns logic
          #                       if false: use short name. columns should be merged and then used
          #

          # key_conditions:- specify atleast partition key, supports use_column_mapping, merge_columns.
          #     outer queries are joined by AND
          #
          # eg:
          # [
          #     {
          #         attribute: {
          #             user_extended_detail_id: 90
          #         },
          #         operator: "="
          #     },
          #     {
          #         attribute: {
          #             user_extended_detail_id: 90,
          #             time: 11
          #         },
          #         operator: "="
          #     }
          # ]
          #


          #
          # filter_conditions:  do not specify any key which is part of primary key.
          #      supports use_column_mapping, merge_columns.
          #
          #     operator:- supported values: =, <, >, <>
          #     logical_operator:- outer queries are joined by this. supported values: AND, OR
          # eg:
          # {
          #     conditions: [
          #         {
          #             attribute: {
          #                 image_processing_status: "processed"
          #             },
          #             operator: "="
          #         },
          #         {
          #             attribute: {
          #                 image_processing_status: "processed",
          #                 time: 12
          #             },
          #             operator: "="
          #         }
          #
          #     ],
          #     logical_operator: "AND"
          # }
          #

          # exclusive_start_key:- used for pagination. does not supports use_column_mapping, merge_columns.
          #     use backend keys name always
          #
          # eg:-
          # {
          #     u_e_id: {n: 90},
          #     u_e_id_ts: {n: 90}
          # }
          #
          # limit:- pass a integer
          #
          # projection_expression:- use same format as in remove - supports use_column_mapping, merge_columns.
          #
          # eg:- when using full name
          # [[:time, :image_processing_status], [:time]]
          #
          # eg:- when using short name
          # [:id, :ued_id_id]
          #

          # index_name- used in query, scan methods of ddb.
          # eg:-
          # "GSI_1"

          # key:- specify primary key, supports use_column_mapping, merge_columns.
          #     outer queries are joined by AND
          #
          # eg:
          # [
          #     {
          #         attribute: {
          #             user_extended_detail_id: 90
          #         },
          #         operator: "="
          #     },
          #     {
          #         attribute: {
          #             user_extended_detail_id: 90,
          #             time: 11
          #         },
          #         operator: "="
          #     }
          # ]
          #
          # [
          #     {
          #         attribute: {
          #             u_e_d_id: 90
          #         },
          #         operator: "="
          #     },
          #     {
          #         attribute: {
          #             u_e_d_id_tm: '90_11'
          #         },
          #         operator: "="
          #     }
          # ]
          #
          #

          # return_values: - String. supported values: NONE | ALL_OLD | UPDATED_OLD | ALL_NEW | UPDATED_NEW
          #

          # item:-  specify atleast primary key, supports use_column_mapping, merge_columns.
          #
          # eg:
          # [
          #     {
          #         attribute: {
          #             user_extended_detail_id: 90
          #         },
          #     },
          #     {
          #         attribute: {
          #             user_extended_detail_id: 90,
          #             time: 11
          #         },
          #     }
          # ]
          #
          # [
          #     {
          #         attribute: {
          #             u_e_d_id: 90
          #         },
          #     },
          #     {
          #         attribute: {
          #             u_e_d_id_tm: '90_11'
          #         },
          #     }
          # ]

          #
          # items: used in Batch Write. Array of item. supports use_column_mapping, merge_columns.
          #
          # eg:
          # [
          #     [
          #         {
          #             attribute: {
          #                 user_extended_detail_id: 90
          #             },
          #         },
          #         {
          #             attribute: {
          #                 user_extended_detail_id: 90,
          #                 time: 11
          #             },
          #         }
          #     ],
          #     [
          #         {
          #             attribute: {
          #                 user_extended_detail_id: 91
          #             },
          #         },
          #         {
          #             attribute: {
          #                 user_extended_detail_id: 91,
          #                 time: 12
          #             },
          #         }
          #     ],
          # ]
          #

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
                    optional: [:return_consumed_capacity, :return_item_collection_metrics]
                }
            }
          end



          # returns partition key
          def partition_key
            nil
          end

          # returns sort key
          def sort_key
            nil
          end

          # Example Usage of index
          # {
          #     index_name: {
          #         partition_key: :id,
          #         sort_key: :timestamp
          #     }
          # }
          #
          # returns list of indexes
          def indexes
            {}
          end

          def variable_type
            {
                number: :n,
                string: :s,
                array: :l,
                hash: :m
            }
          end






        end
      end
    end
  end
end
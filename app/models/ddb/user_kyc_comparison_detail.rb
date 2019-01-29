module Ddb
  class UserKycComparisonDetail
    include Ddb::Table

    table :raw_name => 'user_kyc_comparison_details',
          :partition_keys => GlobalConstant::Aws::Ddb::UserKycComparisonDetail.partition_keys,
          :sort_keys => GlobalConstant::Aws::Ddb::UserKycComparisonDetail.sort_keys,
          :indexes => GlobalConstant::Aws::Ddb::UserKycComparisonDetail.indexes,
          :merged_columns => GlobalConstant::Aws::Ddb::UserKycComparisonDetail.merged_columns,
          :delimiter => "_"

    def initialize(params, options = {})
      @shard_id = params[:shard_id]
      @options = options

      set_table_name

    end

    def set_table_name
      table_info[:name] = "#{Rails.env}_#{@shard_id}_#{self.class.raw_table_name}"
    end

    def use_column_mapping?
      @options[:use_column_mapping].nil? ? false : @options[:use_column_mapping]
    end

  end
end


# update call
# @params = {
#   key: {
# },
# table_name:'',
# update_expression: {
# set: [{
#   attribute: {
#       key: value
# }
#  options: {
#   if_not_exists: true,
#   list_append: true
# }
# }],
# remove: ['', ''],
# add: [{
#   attribute: {
#     key: value
# }
#
# }]
#
# }
#
#
# }
#
#
#
#
#
#
#
#
#
#
#


# Sample params for query api
# @params = {
#     key_conditions: [
#         {
#             attribute: {
#                 user_extended_details_id: 100,
#                 log_type: 1
#             },
#             operator: "="
#         },
#         {
#             attribute: {
#                 timestamp: 100
#
#             },
#             operator: "="
#         }
#     ],
#     filter_conditions: {
#         conditions: [{
#                          attribute: {
#                              key_1: 1223,
#                              key_3: 'ddsds',
#                          },
#                          operator: ">"
#                      },
#                      {
#                          attribute: {
#                              key_2: 4343,
#                          },
#                          operator: "="
#                      },
#         ],
#         logical_operator: "AND"
#     },
#     exclusive_start_key: "sdsds_2323"
# }


# sample params for put_item query
# puts "get_item-------- #{get_item({
#                                       key: {
#                                           user_extended_details_id: '2125',
#                                           log_type: '1'
#                                       }
#                                   })}"
#
#
#





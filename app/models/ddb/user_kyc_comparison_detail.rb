module Ddb
  class UserKycComparisonDetail

    include Ddb::Table

    table :raw_name => 'user_kyc_comparison_details',
          :partition_key => GlobalConstant::Aws::Ddb::UserKycComparisonDetail.partition_key,
          :sort_key => GlobalConstant::Aws::Ddb::UserKycComparisonDetail.sort_key,
          :indexes => GlobalConstant::Aws::Ddb::UserKycComparisonDetail.indexes,
          :merged_columns => GlobalConstant::Aws::Ddb::UserKycComparisonDetail.merged_columns,
          :delimiter => "_"

    def self.image_processing_status_enum
      {
          0 => GlobalConstant::ImageProcessing.unprocessed_image_process_status,
          1 => GlobalConstant::ImageProcessing.processed_image_process_status,
          2 => GlobalConstant::ImageProcessing.failed_image_process_status
      }
    end


    def initialize(params, options = {})

      @params = params
      @options = options

      @shard_id = params[:shard_id]
      set_table_name
    end


    def self.list_of_integer_keys
      ['auto_approve_failed_reasons', 'kyc_auto_approved_status']
    end




    def self.auto_approve_failed_reasons_config
      @auto_approve_failed_reasons_config ||= {
          GlobalConstant::KycAutoApproveFailedReason.unexpected_reason => 1,
          GlobalConstant::KycAutoApproveFailedReason.document_file_invalid => 2,
          GlobalConstant::KycAutoApproveFailedReason.selfie_file_invalid => 4,
          GlobalConstant::KycAutoApproveFailedReason.ocr_unmatch => 8,
          GlobalConstant::KycAutoApproveFailedReason.fr_unmatch => 16,
          GlobalConstant::KycAutoApproveFailedReason.residency_proof => 32,
          GlobalConstant::KycAutoApproveFailedReason.investor_proof => 64,
          GlobalConstant::KycAutoApproveFailedReason.duplicate_kyc => 128,
          GlobalConstant::KycAutoApproveFailedReason.token_sale_ended => 256,
          GlobalConstant::KycAutoApproveFailedReason.case_closed_for_auto_approve => 512,
          GlobalConstant::KycAutoApproveFailedReason.human_labels_percentage_low => 1024
      }
    end

    def auto_approve_failed_reasons_array
      @auto_approve_failed_reasons_array = UserKycComparisonDetail.get_bits_set_for_auto_approve_failed_reasons(auto_approve_failed_reasons)
    end

    # Bitwise columns config

    def self.bit_wise_columns_config
      @b_w_c_c ||= {
          auto_approve_failed_reasons: auto_approve_failed_reasons_config
      }
    end

    include BitWiseConcern

    def initialize_instance_variables(hash)
      hash.each do |k, v|
        instance_variable_set("@#{k}", v)
        self.class.send(:attr_accessor, k)
      end if hash.present?
      self
    end

    def set_table_name
      table_info[:name] = "#{Rails.env}_#{@shard_id}_#{self.class.raw_table_name}"
    end

    def use_column_mapping?
      @options[:use_column_mapping] == false ? false : true
    end

  end
end


# merge column option only used when full names are passed or use_column_mapping is true

#  Update can only be used on primary key for a single row. GSI or secondary indexes cannot be used.
# attribute having multiple keys will be used for merged columns
# key_conditions are always joined with &&
#
# update_item(
{
    key: {
        user_extended_details_id: '2121',
        log_type: '34'
    },
    set: [
        {
            attribute: {
                key_1: 1,
            }
        },
        {
            attribute: {
                key_2: 2,
            }
        },
        {
            attribute: {
                key_1: 1,
                key_2: 4
            }
        },

    ],
    add: [
        {
            attribute: {
                param_2: 32
            }
        }
    ]
}
# )


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
# remove: [[], []],
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


# attribute having multiple keys will be used for merged columns
# all keys in key_conditions, filter_conditions, exclusive_start_key will be mapped
# key_conditions are always joined with &&

# Sample params for query api
@params = {
    key_conditions: [
        {
            attribute: {
                user_extended_detail_id: 7
            },
            operator: "="
        },
        {
            attribute: {
                timestamp: 100
            },
            operator: "="
        }
    ],
    filter_conditions: {
        conditions: [{
                         attribute: {
                             auto_approve_failed_reasons: 0.00,
                         },
                         operator: "="
                     },

                     {
                         attribute: {
                             image_processing_status: "processed"
                         },
                         operator: "="
                     },
                     {
                         attribute: {
                             big_face_match_percent: 100,
                         },
                         operator: "="
                     },
        ],
        logical_operator: "AND"
    },
    #exclusive_start_key: {}
}


# the key should always be the primary key. GSI or secondary indexes cannot be used

# sample params for put_item query
# puts "get_item-------- #{get_item({
#                                       key: {
#                                           user_extended_details_id: '2125',
#                                           log_type: '1'
#                                       }
#                                   })}"
#
#

# key_conditions -> key_conditions
#
# key -> primary_key_conditions


# validate all keys are valid and mandatory keys are present for each function
#


# expressions for index and sort with filter. Which functions and how is it used
#
#
# Ddb::UserKycComparisonDetail.new({shard_id: 's1'}).get_item({
#                                                                 key: [{
#                                                                            attribute: {
#                                                                                user_extended_detail_id: 18
#                                                                            }
#                                                                        }]
#                                                          })

# Ddb::UserKycComparisonDetail.new({shard_id: 's1'}).delete_item({
#                                                                 key: [{
#                                                                            attribute: {
#                                                                                user_extended_detail_id: 4
#                                                                            }
#                                                                        }]
#                                                            })
#
#

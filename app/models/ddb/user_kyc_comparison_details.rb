module Ddb
  class UserKycComparisonDetails
    include Ddb::Table

    table :name => 'user_kyc_comparison_details',
          :partition_keys => GlobalConstant::Aws::Ddb::UserKycComparisonDetails.partition_keys,
          :sort_keys => GlobalConstant::Aws::Ddb::UserKycComparisonDetails.sort_keys,
          :indexes => GlobalConstant::Aws::Ddb::UserKycComparisonDetails.indexes,
          :merged_columns => GlobalConstant::Aws::Ddb::UserKycComparisonDetails.merged_columns

    def initialize(params)
      @attributes = params


      parse_user_id

      @raw_conditions = {
          key_conditions:  [
          {
            attribute: {
                user_extended_details_id: 100,
                log_type: 1
            },
            operator: "="
          },
          {
              attribute: {
                  timestamp: 100

              },
              operator: "="
          }
      ]
      }


      query


    end

    def variable_mapping
      GlobalConstant::Aws::Ddb::UserKycComparisonDetails.variable_mapping
    end

    def table_name
      "#{Rails.env}_#{user_kyc_details.ddb_shard}_#{self.class.raw_table_name}"
    end

    def parse_user_id
      @user_id = @attributes.delete(:user_id)
    end

    def user_kyc_details
      @user_kyc_details ||= UserKycDetail.get_from_memcache(@user_id || 11001)
    end


    def partition_keys
      GlobalConstant::Aws::Ddb::UserKycComparisonDetails.partition_keys
    end


  end
end
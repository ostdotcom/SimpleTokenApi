module GlobalConstant
  module Aws
    module Ddb
      class UserKycComparisonDetails
        class << self


          def merged_columns
            {
                uedi_lt: {
                    keys:  [:user_extended_details_id, :log_type]
                },
                lt: {
                    keys: [:log_type]
                },
                ts: {
                    keys: [:timestamp]
                },
                d_id_n_mp: {
                    keys: [:document_id_number_match_percent]
                }
            }
          end

          def partition_keys
            [:user_extended_details_id, :log_type]
          end

          def sort_keys
            []
          end

          def indexes
            {
                index_name: {
                    partition_key: [],
                    sort_key: []
                }
            }
          end

        end
      end
    end
  end
end
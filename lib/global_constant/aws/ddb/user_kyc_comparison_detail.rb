module GlobalConstant
  module Aws
    module Ddb
      class UserKycComparisonDetail
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
                },
                k_1: {
                    keys: [:key_1]
                },
                k_2: {
                    keys: [:key_2]
                },
                k_3: {
                    keys: [:key_3]
                },
                p2: {
                    keys: [:param_2]
                }
            }.with_indifferent_access
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
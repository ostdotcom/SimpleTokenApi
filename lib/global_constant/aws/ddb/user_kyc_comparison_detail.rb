module GlobalConstant
  module Aws
    module Ddb
      class UserKycComparisonDetail
        class << self

          # column config
          def merged_columns
            {
                u_e_d_i: {
                    keys:  [:user_extended_detail_id]
                },
                c_i: {
                    keys: [:client_id]
                },
                l_i: {
                    keys: [:lock_id]
                },
                d_d: {
                    keys: [:document_dimensions]
                },
                s_d: {
                    keys: [:selfie_dimensions]
                },
                f_n_m_p: {
                    keys: [:first_name_match_percent]
                },
                l_n_m_p: {
                    keys: [:last_name_match_percent]
                },
                b_d_m_p: {
                    keys: [:birthdate_match_percent]
                },
                d_i_n_m_p: {
                    keys: [:document_id_number_match_percent]
                },
                n_m_p: {
                    keys: [:nationality_match_percent]
                },
                b_f_m_p: {
                    keys: [:big_face_match_percent]
                },
                s_f_m_p: {
                    keys: [:small_face_match_percent]
                },
                s_h_l_p: {
                    keys: [:selfie_human_labels_percent]
                },
                i_p_s: {
                    keys: [:image_processing_status]
                },
                k_a_a_s: {
                    keys: [:kyc_auto_approved_status]
                },
                a_a_f_r: {
                    keys: [:auto_approve_failed_reasons]
                },
                c_k_p_s_i: {
                    keys: [:client_kyc_pass_settings_id]
                },
                c_a: {
                    keys: [:created_at]
                },
                u_a: {
                    keys: [:updated_at]
                }
            }.with_indifferent_access
          end

          # keep short name
          # expose a function to return the full name of any short name key
          def partition_key
            :u_e_d_i
          end

          def sort_key

          end

          def indexes
            {
                #     index_name: {
                #         partition_key: [],
                #         sort_key: []
                #     }
            }
          end

        end
      end
    end
  end
end
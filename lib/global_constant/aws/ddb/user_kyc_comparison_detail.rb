module GlobalConstant
  module Aws
    module Ddb
      class UserKycComparisonDetail < Ddb::Base

        class <<  self
          #
          # mapping between long name and backend name(short name)
          def merged_columns
            {
                u_e_d_i: {
                    keys: [{name: :user_extended_detail_id, type: self.variable_type[:number] }]
                },
                c_i: {
                    keys: [{name: :client_id, type:variable_type[:number] }]
                },
                l_i: {
                    keys:  [{name: :lock_id, type: variable_type[:string]  }]
                },
                d_d: {
                    keys: [{name: :document_dimensions, type: variable_type[:hash] }]
                },
                s_d: {
                    keys: [{name: :selfie_dimensions, type: variable_type[:hash] }]
                },
                f_n_m_p: {
                    keys: [{name: :first_name_match_percent, type:variable_type[:number]  }]
                },
                l_n_m_p: {
                    keys:  [{name: :last_name_match_percent, type: variable_type[:number]  }]
                },
                b_d_m_p: {
                    keys: [{name: :birthdate_match_percent, type: variable_type[:number]  }]
                },
                d_i_n_m_p: {
                    keys:[{name: :document_id_number_match_percent, type:variable_type[:number] }]
                },
                n_m_p: {
                    keys: [{name: :nationality_match_percent, type: variable_type[:number]  }]
                },
                b_f_m_p: {
                    keys: [{name: :big_face_match_percent, type: variable_type[:number]  }]
                },
                s_f_m_p: {
                    keys: [{name: :small_face_match_percent, type:variable_type[:number] }]
                },
                s_h_l_p: {
                    keys:  [{name: :selfie_human_labels_percent, type:variable_type[:number] }]
                },
                i_p_s: {
                    keys:  [{name: :image_processing_status, type: variable_type[:number] }]
                },
                k_a_a_s: {
                    keys: [{name: :kyc_auto_approved_status, type:variable_type[:number] }]
                },
                a_a_f_r: {
                    keys: [{name: :auto_approve_failed_reasons, type:variable_type[:number]  }]
                },
                c_k_p_s_i: {
                    keys: [{name: :client_kyc_pass_settings_id, type: variable_type[:number]  }]
                },
                c_a: {
                    keys: [{name: :created_at, type: variable_type[:number] }]
                },
                u_a: {
                    keys: [{name: :updated_at, type: variable_type[:number]  }]
                }
            }.with_indifferent_access
          end

          def partition_key
            :u_e_d_i
          end

        end
      end
    end
  end
end
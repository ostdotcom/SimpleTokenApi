# frozen_string_literal: true
module GlobalConstant

  class UserKycDetail

    class << self

      def cleared_aml_status_deprecated
        'cleared'
      end

      def rejected_aml_status_deprecated
        'rejected'
      end

      def failed_aml_status_deprecated
        'failed'
      end

      ### aml Status Start ###

      def unprocessed_aml_status
        'unprocessed'
      end

      def auto_approved_aml_status
        'auto_approved'
      end

      def pending_aml_status
        'pending'
      end

      def approved_aml_status
        'approved'
      end

      def denied_aml_status
        'denied'
      end

      ### aml Status End ###

      def aml_approved_statuses
        [auto_approved_aml_status, approved_aml_status]
      end

      def admin_approved_statuses
        [qualified_admin_status]
      end

      def aml_open_statuses
        [
            unprocessed_aml_status,
            pending_aml_status
        ]
      end


      ### Admin Status Start ###

      def unprocessed_admin_status
        'unprocessed'
      end

      def qualified_admin_status
        'qualified'
      end

      def denied_admin_status
        'denied'
      end

      ### Admin Status End ###

      ### kyc_status starts###

      def kyc_approved_status
        'approved'
      end

      def kyc_denied_status
        'denied'
      end

      def kyc_pending_status
        'pending'
      end

      ### kyc_status ends###

      ### kyc duplicate state###

      def unprocessed_kyc_duplicate_status
        'unprocessed'
      end

      def never_kyc_duplicate_status
        'never'
      end

      def is_kyc_duplicate_status
        'is'
      end

      def was_kyc_duplicate_status
        'was'
      end

      ### kyc duplicate state ends###

      ### email duplicate state###

      def yes_email_duplicate_status
        'yes'
      end

      def no_email_duplicate_status
        'no'
      end

      ### email duplicate state ends###

      ### whitelist status ####

      def unprocessed_whitelist_status
        'unprocessed'
      end

      def started_whitelist_status
        'started'
      end

      def done_whitelist_status
        'done'
      end

      def failed_whitelist_status
        'failed'
      end

      ### whitelist status ####


      # ### admin action type ####

      def data_mismatch_admin_action_type
        'data_mismatch'
      end

      def document_issue_admin_action_type
        'document_issue'
      end

      def other_issue_admin_action_type
        'other_issue'
      end


      # def no_admin_action_type
      #   'no'
      # end
      #
      # def data_mismatch_admin_action_type
      #   'data_mismatch'
      # end
      #
      # def document_id_issue_admin_action_type
      #   'document_id_issue'
      # end
      #
      # def selfie_issue_admin_action_type
      #   'selfie_issue'
      # end
      #
      # def residency_issue_admin_action_type
      #   'residency_issue'
      # end
      #

      # ### admin action type ####


      ### qualify type start ###

      def auto_approved_qualify_type
        "auto_approved"
      end

      def manually_approved_qualify_type
        "manually_approved"
      end

      ### qualify type end ###


      ######### Documents REGEX START ############

      def s3_document_path_regex
        /\A[A-Z0-9\/]+\Z/i
      end

      def s3_document_image_path_regex
        /\A([A-Z0-9\/]*\/)*i\/[A-Z0-9\/]+\Z/i
      end

      ######### Documents REGEX END ############


      ### Status Start ###

      def active_status
        'active'
      end

      def inactive_status
        'inactive'
      end

      ### Status End ###


      #################### Filter keys ##################################
      def admin_action_types_key
        'admin_action_types'
      end

      def admin_status_key
        'admin_status'
      end

      def aml_status_key
        'aml_status'
      end

      def whitelist_status_key
        'whitelist_status'
      end

      def filters
        {
            "#{admin_status_key}" => {
                "#{unprocessed_admin_status}" => [unprocessed_admin_status],
                "#{qualified_admin_status}" => [qualified_admin_status],
                "#{denied_admin_status}" => [denied_admin_status]
            },

            "#{aml_status_key}" => {
                "#{auto_approved_aml_status}:#{approved_aml_status}" => [auto_approved_aml_status, approved_aml_status],
                "#{unprocessed_aml_status}" => [unprocessed_aml_status],
                "#{pending_aml_status}" => [pending_aml_status],
                "#{auto_approved_aml_status}" => [auto_approved_aml_status],
                "#{approved_aml_status}" => [approved_aml_status],
                "#{denied_aml_status}" => [denied_aml_status]
            },
            "#{whitelist_status_key}" => {
                "#{unprocessed_whitelist_status}" => [unprocessed_whitelist_status],
                "#{started_whitelist_status}" => [started_whitelist_status],
                "#{done_whitelist_status}" => [done_whitelist_status],
                "#{failed_whitelist_status}" => [failed_whitelist_status]
            },
            "#{admin_action_types_key}" => {
                "no_admin_action" => {admin_action_types: 0},
                "#{data_mismatch_admin_action_type}" => ["(admin_action_types & ?) = ?",
                                                         ::UserKycDetail.use_any_instance.admin_action_types_config[data_mismatch_admin_action_type],
                                                         ::UserKycDetail.use_any_instance.admin_action_types_config[data_mismatch_admin_action_type]
                ],
                "#{document_issue_admin_action_type}" => ["(admin_action_types & ?) = ?",
                                                          ::UserKycDetail.use_any_instance.admin_action_types_config[document_issue_admin_action_type],
                                                          ::UserKycDetail.use_any_instance.admin_action_types_config[document_issue_admin_action_type]
                ],
                "#{other_issue_admin_action_type}" => ["(admin_action_types & ?) = ?",
                                                       ::UserKycDetail.use_any_instance.admin_action_types_config[other_issue_admin_action_type],
                                                       ::UserKycDetail.use_any_instance.admin_action_types_config[other_issue_admin_action_type]
                ]
            }
        }
      end

      def filters_v2_deprecated
        {
            "#{admin_status_key}" => {
                "#{unprocessed_admin_status}" => [unprocessed_admin_status],
                "#{qualified_admin_status}" => [qualified_admin_status],
                "#{denied_admin_status}" => [denied_admin_status]
            },
            "#{aml_status_key}" => {
                "#{cleared_aml_status_deprecated}:#{approved_aml_status}" => [auto_approved_aml_status, approved_aml_status],
                "#{unprocessed_aml_status}" => [unprocessed_aml_status],
                "#{pending_aml_status}" => [pending_aml_status],
                "#{cleared_aml_status_deprecated}" => [auto_approved_aml_status],
                "#{approved_aml_status}" => [approved_aml_status],
                "#{rejected_aml_status_deprecated}" => [denied_aml_status],
                "#{failed_aml_status_deprecated}" => [] # will make 0=1 query and hence no records as needed
            },
            "#{whitelist_status_key}" => {
                "#{unprocessed_whitelist_status}" => [unprocessed_whitelist_status],
                "#{started_whitelist_status}" => [started_whitelist_status],
                "#{done_whitelist_status}" => [done_whitelist_status],
                "#{failed_whitelist_status}" => [failed_whitelist_status]
            },
            "#{admin_action_types_key}" => {
                "no_admin_action" => {admin_action_types: 0},
                "#{data_mismatch_admin_action_type}" => ["(admin_action_types & ?) = ?",
                                                         ::UserKycDetail.use_any_instance.admin_action_types_config[data_mismatch_admin_action_type],
                                                         ::UserKycDetail.use_any_instance.admin_action_types_config[data_mismatch_admin_action_type]
                ],
                "#{document_issue_admin_action_type}" => ["(admin_action_types & ?) = ?",
                                                          ::UserKycDetail.use_any_instance.admin_action_types_config[document_issue_admin_action_type],
                                                          ::UserKycDetail.use_any_instance.admin_action_types_config[document_issue_admin_action_type]
                ],
                "#{other_issue_admin_action_type}" => ["(admin_action_types & ?) = ?",
                                                       ::UserKycDetail.use_any_instance.admin_action_types_config[other_issue_admin_action_type],
                                                       ::UserKycDetail.use_any_instance.admin_action_types_config[other_issue_admin_action_type]
                ]
            }
        }
      end

      # This is also used in user list sortings
      def sorting
        {
            "order" => {
                'desc' => {user_extended_detail_id: :desc},
                'asc' => {user_extended_detail_id: :asc}
            }
        }
      end

    end

  end

end

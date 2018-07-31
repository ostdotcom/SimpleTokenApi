# frozen_string_literal: true
module GlobalConstant

  class UserKycDetail

    class << self

      ### Cynopsis Status Start ###

      def unprocessed_cynopsis_status
        'unprocessed'
      end

      def cleared_cynopsis_status
        'cleared'
      end

      def pending_cynopsis_status
        'pending'
      end

      def approved_cynopsis_status
        'approved'
      end

      def rejected_cynopsis_status
        'rejected'
      end

      def failed_cynopsis_status
        'failed'
      end

      ### Cynopsis Status End ###

      def cynopsis_approved_statuses
        [cleared_cynopsis_status, approved_cynopsis_status]
      end

      def admin_approved_statuses
        [qualified_admin_status]
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

      # Get mapped cynopsis status from response status of cynopsis call
      #
      # * Author: Aman
      # * Date: 24/10/2017
      # * Reviewed By: Sunil
      #
      #return[String] returns mapping of cynopsis status
      #
      def get_cynopsis_status(approval_status)

        if approval_status == 'PENDING'
          pending_cynopsis_status
        elsif approval_status == 'CLEARED'
          cleared_cynopsis_status
        elsif approval_status == 'ACCEPTED'
          approved_cynopsis_status
        elsif approval_status == 'REJECTED'
          rejected_cynopsis_status
        else
          unprocessed_cynopsis_status
        end
      end

      def filters
        {
            "admin_status" => {
                "all" => [],
                "#{unprocessed_admin_status}" => [unprocessed_admin_status],
                "#{qualified_admin_status}" => [qualified_admin_status],
                "#{denied_admin_status}" => [denied_admin_status]
            },

            "cynopsis_status" => {
                "all" => [],
                "#{cleared_cynopsis_status}:#{approved_cynopsis_status}" => [cleared_cynopsis_status, approved_cynopsis_status],
                "#{unprocessed_cynopsis_status}" => [unprocessed_cynopsis_status],
                "#{pending_cynopsis_status}" => [pending_cynopsis_status],
                "#{cleared_cynopsis_status}" => [cleared_cynopsis_status],
                "#{approved_cynopsis_status}" => [approved_cynopsis_status],
                "#{rejected_cynopsis_status}" => [rejected_cynopsis_status],
                "#{failed_cynopsis_status}" => [failed_cynopsis_status]
            },
            "whitelist_status" => {
                "all" => [],
                "#{unprocessed_whitelist_status}" => [unprocessed_whitelist_status],
                "#{started_whitelist_status}" => [started_whitelist_status],
                "#{done_whitelist_status}" => [done_whitelist_status],
                "#{failed_whitelist_status}" => [failed_whitelist_status]
            },
            "admin_action_types" => {
                "all" => {},
                "no_admin_action" => {admin_action_types: 0},
                "#{data_mismatch_admin_action_type}" => ["(admin_action_types & ?) = ?",
                                                         ::UserKycDetail.admin_action_types_config[data_mismatch_admin_action_type],
                                                         ::UserKycDetail.admin_action_types_config[data_mismatch_admin_action_type]
                ],
                "#{document_issue_admin_action_type}" => ["(admin_action_types & ?) = ?",
                                                          ::UserKycDetail.admin_action_types_config[document_issue_admin_action_type],
                                                          ::UserKycDetail.admin_action_types_config[document_issue_admin_action_type]
                ],
                "#{other_issue_admin_action_type}" => ["(admin_action_types & ?) = ?",
                                                       ::UserKycDetail.admin_action_types_config[other_issue_admin_action_type],
                                                       ::UserKycDetail.admin_action_types_config[other_issue_admin_action_type]
                ]
            }
        }
      end

      # This is also used in user list sortings
      def sorting
        {
            "sort_by" => {
                'desc' => {user_extended_detail_id: :desc},
                'asc' => {user_extended_detail_id: :asc}
            }
        }
      end

    end

  end

end

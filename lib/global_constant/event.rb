module GlobalConstant

  class Event

    class << self

      ### result_type start ###

      def user_result_type
        'user'
      end

      def user_kyc_result_type
        'user_kyc'
      end

      ### result_type end ###

      ### source start ###

      def web_source
        'web'
      end

      def api_source
        'api'
      end

      def kyc_system_source
        'kyc_system'
      end

      ### source end ###


      ### name start ###

      def user_register_name
        'user_register'
      end

      def user_dopt_in_name
        'user_dopt_in'
      end

      def user_deleted_name
        'user_deleted'
      end

      def kyc_submit_name
        'kyc_submit'
      end

      def update_ethereum_address_name
        'update_ethereum_address'
      end

      def kyc_status_update_name
        'kyc_status_update'
      end

      def kyc_reopen_name
        'kyc_reopen'
      end

      ### name end ###


      ## sample events begin ##

      def user_register_event_data
        {
            user: {
                created_at: Time.now.to_i,
                email: "sampletest@ost.com",
                id: "11493",
                properties: [
                    "doptin_mail_sent"
                ]
            }
        }
      end

      def user_dopt_in_event_data
        {
            user: {
                created_at: Time.now.to_i,
                email: "sampletest@ost.com",
                id: "11493",
                properties: [
                    "doptin_mail_sent",
                    "doptin_done"
                ]
            }
        }
      end

      def user_deleted_event_data
        {
            user: {
                created_at: Time.now.to_i,
                email: "sampletest@ost.com",
                id: "11493",
                properties: [
                    "doptin_mail_sent",
                    "doptin_done",
                    "kyc_submitted"
                ]
            }
        }
      end

      def kyc_submit_event_data
        {
            user_kyc_detail: {
                admin_status: "unprocessed",
                aml_status: "cleared",
                admin_action_types_array: [],
                created_at: Time.now.to_i,
                id: "337",
                kyc_status: "pending",
                last_acted_by: nil,
                submission_count: "2",
                user_id: "11493",
                user_extended_detail_id: "820",
                whitelist_status: "unprocessed"
            },
            admin: {
                name: ""
            }
        }
      end

      def update_ethereum_address_event_data
        {
            user_kyc_detail: {
                admin_status: "unprocessed",
                aml_status: "cleared",
                admin_action_types_array: ['data_mismatch'],
                created_at: Time.now.to_i,
                id: "337",
                kyc_status: "pending",
                last_acted_by: 1,
                submission_count: "2",
                user_id: "11493",
                user_extended_detail_id: "820",
                whitelist_status: "unprocessed"
            },
            admin: {
                name: "AdminName"
            }
        }
      end

      def kyc_status_update_event_data
        {
            user_kyc_detail: {
                admin_status: "qualified",
                aml_status: "cleared",
                admin_action_types_array: [],
                created_at: Time.now.to_i,
                id: "337",
                kyc_status: "approved",
                last_acted_by: 1,
                submission_count: "2",
                user_id: "11493",
                user_extended_detail_id: "820",
                whitelist_status: "unprocessed"
            },
            admin: {
                name: "AdminName"
            }
        }
      end

      def kyc_reopen_event_data
        {
            user_kyc_detail: {
                admin_status: "unprocessed",
                aml_status: "cleared",
                admin_action_types_array: [],
                created_at: Time.now.to_i,
                id: "337",
                kyc_status: "pending",
                last_acted_by: 1,
                submission_count: "2",
                user_id: "11493",
                user_extended_detail_id: "820",
                whitelist_status: "unprocessed"
            },
            admin: {
                name: "AdminName"
            }
        }
      end

      ## sample events end ##


    end

  end
end

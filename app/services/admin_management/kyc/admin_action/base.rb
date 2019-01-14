module AdminManagement
  module Kyc
    module AdminAction
      class Base < ServicesBase

        # Initialize
        #
        # * Author: Mayur
        # * Date: 11/1/19
        # * Reviewed By:
        #
        # @params [Integer] admin_id (mandatory) - logged in admin
        # @params [Integer] client_id (mandatory) - logged in admin's client id
        # @params [Integer] id (mandatory) - case id
        #
        # @return [AdminManagement::Kyc::AdminAction::Base]
        #
        def initialize(params)
          super

          @admin_id = @params[:admin_id]
          @client_id = @params[:client_id]
          @case_id = @params[:id]
          @api_response_data = {}
          @extra_data = {}
          @user_kyc_detail = nil
        end


        # validate and sanitize
        #
        # * Author: Mayur
        # * Date: 11/1/19
        # * Reviewed By:
        #
        def validate_and_sanitize
          r = validate
          return r unless r.success?

          r = fetch_and_validate_client
          return r unless r.success?

          r = fetch_and_validate_admin
          return r unless r.success?

          @user_kyc_detail = UserKycDetail.where(client_id: @client_id, id: @case_id).first

          return error_with_data(
              'ka_b_vs_1',
              'KYC not found',
              'KYC not found',
              GlobalConstant::ErrorAction.default,
              {}
          ) if @user_kyc_detail.blank? || @user_kyc_detail.inactive_status?

          return error_with_data(
              'ka_b_vs_4',
              'Case is already closed.',
              'Case is already closed.',
              GlobalConstant::ErrorAction.default,
              {}
          ) if @user_kyc_detail.case_closed?

          success
        end

        # validate for duplicate users
        #
        # * Author: Mayur
        # * Date: 11/1/19
        # * Reviewed By:
        #
        def validate_for_duplicate_user
          if UserExtendedDetail.is_duplicate_kyc_approved_user?(@user_kyc_detail.client_id,
                                                                @user_kyc_detail.user_extended_detail_id)
            return error_with_data(
                GlobalConstant::KycAutoApproveFailedReason.duplicate_kyc,
                'Duplicate Kyc User for approval.',
                'Duplicate Kyc User for approval.',
                GlobalConstant::ErrorAction.default,
                {}
            )
          end
          success
        end

        # aml search instance
        #
        # * Author: Mayur
        # * Date: 11/1/19
        # * Reviewed By:
        #
        def aml_search
          @aml_search ||= AmlSearch.where(user_kyc_detail_id: @user_kyc_detail.id,
                                          user_extended_detail_id: @user_kyc_detail.user_extended_detail_id).first
        end

        # aml matches instance
        #
        # * Author: Mayur
        # * Date: 11/1/19
        # * Reviewed By:
        #
        def aml_matches
          @aml_matches ||= is_aml_processing_done? ? AmlMatch.where(aml_search_uuid: aml_search.uuid).all : []
        end

        # send approval email
        #
        # * Author: Mayur
        # * Date: 11/1/19
        # * Reviewed By:
        #
        def send_approved_email
          return if !@user_kyc_detail.kyc_approved? || !@client.is_email_setup_done? || @client.is_whitelist_setup_done? ||
              @client.is_st_token_sale_client? || !@client.client_kyc_config_detail.auto_send_kyc_approve_email?

          @user = User.where(client_id: @client_id, id: @user_kyc_detail.user_id).first

          Email::HookCreator::SendTransactionalMail.new(
              client_id: @client.id,
              email: @user.email,
              template_name: GlobalConstant::PepoCampaigns.kyc_approved_template,
              template_vars: GlobalConstant::PepoCampaigns.kyc_approve_default_template_vars(@client_id)
          ).perform
        end

        # update aml matches records
        #
        # * Author: Mayur
        # * Date: 11/1/19
        # * Reviewed By:
        #
        def update_aml_match_status
          if aml_matches.present? && (@matched_ids + @unmatched_ids).present?

            marked_as_match = aml_matches.map {|x| x.qr_code if x.status == GlobalConstant::AmlMatch.match_status}
            marked_as_nomatch = aml_matches.map {|x| x.qr_code if x.status == GlobalConstant::AmlMatch.no_match_status}

            mark_as_match = @matched_ids - marked_as_match
            mark_as_nomatch = @unmatched_ids - marked_as_nomatch


            if mark_as_match.present?
              aml_matches.where(qr_code: mark_as_match).update_all(status: GlobalConstant::AmlMatch.match_status)
            end

            if mark_as_nomatch.present?
              aml_matches.where(qr_code: mark_as_nomatch).update_all(status: GlobalConstant::AmlMatch.no_match_status)
            end

            bulk_flush_matches_memcache(aml_matches[0]) if (mark_as_match + mark_as_nomatch).present?

            # unprocessed_matches = aml_matches.map(&:qr_code) - (@matched_ids + @unmatched_ids)
            # aml_matches.where(qr_code: unprocessed_matches).update_all(status: GlobalConstant::AmlMatch.unprocessed_status) if unprocessed_matches.present?
          end
        end

        # validate matched and unmatched records
        #
        # * Author: Mayur
        # * Date: 11/1/19
        # * Reviewed By:
        #
        def validate_matched_unmatched_records

          r = check_if_common_matched_unmatched_records
          return r unless r.success?

          r = validate_matched_unmatched_ids
          return r unless r.success?

          success

        end

        # validate all matched and unmatched present in aml_match table
        #
        # * Author: Mayur
        # * Date: 11/1/19
        # * Reviewed By:
        #
        def validate_matched_unmatched_ids
          return error_with_data(
              'ka_b_vmi_1',
              'Invalid Input. incorrect matched ids',
              'Invalid Input. incorrect matched ids',
              GlobalConstant::ErrorAction.default,
              {}
          ) if ((@matched_ids + @unmatched_ids) - aml_matches.map(&:qr_code)).present?
          success
        end


        # check if common matched unmatched records
        #
        # * Author: Mayur
        # * Date: 11/1/19
        # * Reviewed By:
        #
        def check_if_common_matched_unmatched_records
          return error_with_data(
              'ka_ad_vm_1',
              'Invalid Input.Record can not be matched and unmatched together',
              'Invalid Input.Record can not be matched and unmatched together',
              GlobalConstant::ErrorAction.default,
              {}
          ) if (@matched_ids & @unmatched_ids).present?
          success
        end

        # check if aml search has been processed
        #
        # * Author: mayur
        # * Date: 10/01/2019
        # * Reviewed By:
        #
        # @return [Boolean]
        #
        def is_aml_processing_done?
          aml_search.present? && aml_search.status == GlobalConstant::AmlSearch.processed_status
        end

        # enqueue job
        #
        # * Author: Mayur
        # * Date: 11/1/19
        # * Reviewed By:
        #
        def enqueue_job
          BgJob.enqueue(
              WebhookJob::RecordEvent,
              {
                  client_id: @user_kyc_detail.client_id,
                  event_source: event_source,
                  event_name: GlobalConstant::Event.kyc_status_update_name,
                  event_data: {
                      user_kyc_detail: @user_kyc_detail.get_hash,
                      admin: @admin.get_hash
                  },
                  event_timestamp: Time.now.to_i
              }
          )

        end

        # logs admin actions
        #
        # * Author: Mayur
        # * Date: 11/1/19
        # * Reviewed By:
        #
        def log_admin_action
          BgJob.enqueue(
              UserActivityLogJob,
              {
                  user_id: @user_kyc_detail.user_id,
                  case_id: @case_id,
                  admin_id: @admin_id,
                  action: logging_action_type,
                  action_timestamp: Time.now.to_i,
                  extra_data: @extra_data
              }
          )
        end

        # get event source
        #
        # * Author: Mayur
        # * Date: 11/1/19
        # * Reviewed By:
        #
        def event_source
          GlobalConstant::Event.web_source
        end


        # user action log table action name
        #
        # * Author: Mayur
        # * Date: 10/1/19
        # * Reviewed By:
        #
        def logging_action_type
          fail 'unimplemented method logging_action_type'
        end

        # fetch case details
        #
        # * Author: Mayur
        # * Date: 14/1/19
        # * Reviewed By:
        #
        def fetch_case_details
          AdminManagement::Kyc::CheckDetails.new({client_id: @client_id, admin_id: @admin_id, id: @case_id}).perform
        end

      end
    end
  end
end
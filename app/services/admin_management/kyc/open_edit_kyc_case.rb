module AdminManagement

  module Kyc

    class OpenEditKycCase < ServicesBase

      # Initialize
      #
      # * Author: Pankaj
      # * Date: 02/05/2018
      # * Reviewed By:
      #
      # @params [Integer] admin_id (mandatory) - logged in admin
      # @params [Integer] client_id (mandatory) - logged in admin's client id
      # @params [Integer] case_id (mandatory) - search term to find case
      #
      # @return [AdminManagement::Kyc::OpenEditKycCase]
      #
      def initialize(params)
        super

        @admin_id = @params[:admin_id]
        @client_id = @params[:client_id]
        @case_id = @params[:id]

        @user_kyc_detail = nil
      end

      # Perform
      #
      # * Author: Pankaj
      # * Date: 02/05/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def perform

        r = validate_and_sanitize
        return r unless r.success?

        create_edit_kyc_request

        r = open_case
        return r unless r.success?

        success_with_data(r.data)
      end

      private

      # Validate all the Input parameters before posting Edit Kyc Requests
      #
      # * Author: Pankaj
      # * Date: 04/05/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def validate_and_sanitize
        r = validate
        return r unless r.success?

        r = fetch_and_validate_client
        return r unless r.success?

        # Default Client is not allowed to open case
        return error_with_data(
            'am_k_oekc_1',
            'Open Case Actions not allowed for Token Sale Client.',
            'Open Case Actions not allowed for Token Sale Client.',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @client.is_st_token_sale_client?

        r = fetch_and_validate_admin
        return r unless r.success?

        return error_with_data(
            'am_k_oekc_2',
            'Admin does not have rights to perform this action.',
            'Admin does not have rights to perform this action.',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @admin.default_client_id != @client.id

        # Check for pending edit kyc requests
        edit_kyc_request = EditKycRequests.under_process.where(case_id: @case_id).first

        return error_with_data(
            'am_k_oekc_3',
            'Edit request is in process for this case.',
            'Edit request is in process for this case.',
            GlobalConstant::ErrorAction.default,
            {}
        ) if edit_kyc_request.present?

        @user_kyc_detail = UserKycDetail.where(client_id: @client_id, id: @case_id).first
        return error_with_data(
            'am_k_oekc_4',
            'KYC detail not found or its already open.',
            'Kyc Details not found or its already open.',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @user_kyc_detail.blank? || @user_kyc_detail.inactive_status? || !@user_kyc_detail.case_closed?


        r = validate_is_whitelist_in_process
        return r unless r.success?

        success
      end

      # Validate is whitelist in process
      #
      # * Author: Pankaj
      # * Date: 02/05/2018
      # * Reviewed By:
      #
      # @return [Result::Base]
      #
      def validate_is_whitelist_in_process
        return success unless @client.is_whitelist_setup_done?

        if @user_kyc_detail.kyc_approved? && !@user_kyc_detail.whitelist_confirmation_done?

          return error_with_data(
              'am_k_oekc_6',
              "Whitelist confirmation is still pending. Please try after sometime.",
              "Whitelist confirmation is still pending. Please try after sometime.",
              GlobalConstant::ErrorAction.default,
              {}
          )
        end

        success
      end

      # Create Edit KYC request for a user
      #
      # * Author: Pankaj
      # * Date: 07/05/2018
      # * Reviewed By:
      #
      # Sets @edit_kyc_request
      #
      def create_edit_kyc_request
        @edit_kyc_request = EditKycRequests.create!(
            case_id: @case_id,
            admin_id: @admin_id,
            user_id: @user_kyc_detail.user_id,
            update_action: GlobalConstant::EditKycRequest.open_case_update_action,
            status: GlobalConstant::EditKycRequest.in_process_status
        )
      end

      # Check for client whitelisting services and then open case.
      #
      # * Author: Pankaj
      # * Date: 07/05/2018
      # * Reviewed By:
      #
      def open_case
        # If client has whitelisting activated then send unwhitelist request.
        # If user kyc is approved then only send unwhitelist
        case_opened = false
        if @client.is_whitelist_setup_done? && @user_kyc_detail.kyc_approved?
          enqueue_unwhitelist_request

        else
          r = mark_user_kyc_unprocessed
          return r unless r.success?

          update_edit_kyc_request(GlobalConstant::EditKycRequest.processed_status)

          log_activity

          case_opened = true
        end

        success_with_data({is_processing: !case_opened})
      end

      # Mark user kyc as unprocessed.
      #
      # * Author: Pankaj
      # * Date: 07/05/2018
      # * Reviewed By:
      #
      def mark_user_kyc_unprocessed
        @user_kyc_detail.admin_status = GlobalConstant::UserKycDetail.unprocessed_admin_status
        @user_kyc_detail.aml_status = GlobalConstant::UserKycDetail.pending_aml_status if @user_kyc_detail.aml_status != GlobalConstant::UserKycDetail.unprocessed_aml_status
        @user_kyc_detail.aml_user_id = nil
        @user_kyc_detail.whitelist_status = GlobalConstant::UserKycDetail.unprocessed_whitelist_status
        @user_kyc_detail.last_acted_by = @admin_id
        @user_kyc_detail.last_acted_timestamp = Time.now.to_i
        @user_kyc_detail.kyc_confirmed_at = nil
        @user_kyc_detail.last_reopened_at = Time.now.to_i
        if @user_kyc_detail.save!
          enqueue_job
          return success
        else
          return error_with_data(
              'am_k_c_caaoc_5',
              'Something went wrong',
              '',
              GlobalConstant::ErrorAction.default,
              {}
          )
        end
      end

      # Log admin activity on user's Kyc
      #
      # * Author: Pankaj
      # * Date: 07/05/2018
      # * Reviewed By:
      #
      def log_activity

        BgJob.enqueue(
            UserActivityLogJob,
            {
                user_id: @user_kyc_detail.user_id,
                admin_id: @admin.id,
                action: GlobalConstant::UserActivityLog.open_case,
                action_timestamp: Time.now.to_i,
                extra_data: {
                    case_id: @case_id
                }
            }
        )

        success
      end

      # Update Edit Kyc requests entry with passed status
      #
      # * Author: Pankaj
      # * Date: 07/05/2018
      # * Reviewed By:
      #
      # @status [Integer] status (mandatory) - Status to be set for Edit kyc entry
      #
      def update_edit_kyc_request(status)
        @edit_kyc_request.status = status
        @edit_kyc_request.save!
      end

      # Enqueue Unwhitelisting
      #
      # * Author: Pankaj
      # * Date: 09/05/2018
      # * Reviewed By:
      #
      def enqueue_unwhitelist_request

        BgJob.enqueue(
            UnwhitelistAddressJob,
            {
                edit_kyc_id: @edit_kyc_request.id,
                user_extended_detail_id: @user_kyc_detail.user_extended_detail_id,
                client_id: @client_id,
                user_kyc_detail_id: @user_kyc_detail.id,
                admin_email: @admin.email,
                user_id: @user_kyc_detail.user_id
            }
        )

      end

      # Do remaining task in sidekiq
      #
      # * Author: Tejas
      # * Date: 16/10/2018
      # * Reviewed By:
      #
      def enqueue_job
        BgJob.enqueue(
            WebhookJob::RecordEvent,
            {
                client_id: @user_kyc_detail.client_id,
                event_source: GlobalConstant::Event.web_source,
                event_name: GlobalConstant::Event.kyc_reopen_name,
                event_data: {
                    user_kyc_detail: @user_kyc_detail.get_hash,
                    admin: @admin.get_hash
                },
                event_timestamp: Time.now.to_i
            }
        )

      end

    end

  end

end

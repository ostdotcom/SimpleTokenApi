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

        success
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

        r = fetch_and_validate_admin
        return r unless r.success?

        return error_with_data(
            'am_k_oekc_1',
            'Admin does not have rights to perform this action.',
            'Admin does not have rights to perform this action.',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @admin.default_client_id != @client.id

        # Check for pending edit kyc requests
        edit_kyc_request = EditKycRequests.under_process.where(case_id: @case_id).first

        return error_with_data(
            'am_k_oekc_2',
            'Edit request is in process for this case.',
            'Edit request is in process for this case.',
            GlobalConstant::ErrorAction.default,
            {}
        ) if edit_kyc_request.present?

        @user_kyc_detail = UserKycDetail.where(client_id: @client_id, id: @case_id).first
        return error_with_data(
            'am_k_oekc_3',
            'KYC detail not found or its already open.',
            '',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @user_kyc_detail.blank? || !@user_kyc_detail.case_closed?

        return error_with_data(
            'am_k_oekc_4',
            'Case is rejected by Cynopsis',
            '',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @user_kyc_detail.cynopsis_rejected?

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
            open_case_only: 1,
            update_action: GlobalConstant::UserKycDetail.open_case_update_action,
            status: GlobalConstant::UserKycDetail.in_process_edit_kyc
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
        if @client.is_whitelist_setup_done? && @user_kyc_detail.kyc_approved?
          enqueue_unwhitelist_request

        else
          r = mark_user_kyc_unprocessed
          return r unless r.success?

          update_edit_kyc_request(GlobalConstant::UserKycDetail.processed_edit_kyc)

          log_activity
        end

        success
      end

      # Mark user kyc as unprocessed.
      #
      # * Author: Pankaj
      # * Date: 07/05/2018
      # * Reviewed By:
      #
      def mark_user_kyc_unprocessed

        @user_kyc_detail.admin_status = GlobalConstant::UserKycDetail.unprocessed_admin_status
        @user_kyc_detail.whitelist_status = GlobalConstant::UserKycDetail.unprocessed_whitelist_status
        @user_kyc_detail.last_acted_by = @admin_id
        @user_kyc_detail.last_acted_timestamp = Time.now.to_i
        if @user_kyc_detail.save!
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

    end

  end

end

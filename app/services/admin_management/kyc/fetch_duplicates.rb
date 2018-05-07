module AdminManagement

  module Kyc

    class FetchDuplicates < ServicesBase

      # Initialize
      #
      # * Author: Kedar
      # * Date: 14/10/2017
      # * Reviewed By: Sunil
      #
      # @params [Integer] admin_id (mandatory) - logged in admin
      # @params [Integer] client_id (mandatory) - logged in admin's client id
      # @params [Integer] id (mandatory) - user kyc details id
      #
      # @return [AdminManagement::Kyc::FetchDuplicates]
      #
      def initialize(params)
        super

        @admin_id = @params[:admin_id]
        @client_id = @params[:client_id]
        @case_id = @params[:id]

        @duplicate_kycs = {}
        @api_response_data = {}
      end

      # Perform
      #
      # * Author: Kedar
      # * Date: 14/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Result::Base]
      #
      def perform

        r = validate_and_sanitize
        return r unless r.success?

        get_duplicate_kyc_data

        get_duplicate_email_data

        format_duplicate_data

        set_api_response_data

        success_with_data(@api_response_data)
      end

      private

      # validate and sanitize
      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      # @return [Result::Base]
      #
      def validate_and_sanitize
        r = validate
        return r unless r.success?

        @user_kyc_detail = UserKycDetail.where(client_id: @client_id, id: @case_id).first
        return error_with_data(
            'am_k_fd_1',
            'KYC detail id not found',
            '',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @user_kyc_detail.blank?

        r = fetch_and_validate_client
        return r unless r.success?

        r = fetch_and_validate_admin
        return r unless r.success?

        success
      end

      # fetch duplicate kyc data if there are any
      #
      # * Author: Kedar, Puneet
      # * Date: 12/10/2017
      # * Reviewed By: Sunil
      #
      # Sets @duplicate_kycs
      #
      def get_duplicate_kyc_data
        return unless @user_kyc_detail.show_duplicate_status

        duplicate_with_users = []

        duplicate_with_users += UserKycDuplicationLog.where(user1_id: @user_kyc_detail.user_id, user_extended_details1_id: @user_kyc_detail.user_extended_detail_id)
                                    .order('status ASC, id DESC').limit(100).all
        duplicate_with_users += UserKycDuplicationLog.where(user2_id: @user_kyc_detail.user_id, user_extended_details2_id: @user_kyc_detail.user_extended_detail_id)
                                    .order('status ASC, id DESC').limit(100).all
        duplicate_with_users.each do |duplicate|
          duplicate_with_uid = (duplicate.user1_id == @user_kyc_detail.user_id) ? duplicate.user2_id : duplicate.user1_id
          @duplicate_kycs[duplicate_with_uid] ||= {
              GlobalConstant::UserKycDuplicationLog.active_status.to_sym => [],
              GlobalConstant::UserKycDuplicationLog.inactive_status.to_sym => []
          }
          if @duplicate_kycs[duplicate_with_uid][duplicate.status.to_sym].exclude?(duplicate.duplicate_type)
            @duplicate_kycs[duplicate_with_uid][duplicate.status.to_sym] << duplicate.duplicate_type
          end
        end

        UserKycDetail.where(client_id: @client_id, user_id: @duplicate_kycs.keys).each do |u_k_d|
          @duplicate_kycs[u_k_d.user_id][:id] = u_k_d.id
          @duplicate_kycs[u_k_d.user_id][:admin_status] = u_k_d.admin_status
          @duplicate_kycs[u_k_d.user_id][:cynopsis_status] = u_k_d.cynopsis_status
        end

      end

      # fetch duplicate email data if there are any
      #
      # * Author: Aman
      # * Date: 21/10/2017
      # * Reviewed By:
      #
      # Sets @duplicate_kycs
      #
      def get_duplicate_email_data
        return if @user_kyc_detail.no_email_duplicate_status?

        duplicate_email_user_ids = []

        duplicate_email_user_ids += UserEmailDuplicationLog.where(user1_id: @user_kyc_detail.user_id, status: GlobalConstant::UserEmailDuplicationLog.active_status).pluck(:user2_id)
        duplicate_email_user_ids += UserEmailDuplicationLog.where(user2_id: @user_kyc_detail.user_id, status: GlobalConstant::UserEmailDuplicationLog.active_status).pluck(:user1_id)

        UserKycDetail.where(client_id: @client_id, user_id: duplicate_email_user_ids).all.each do |u_k_d|
          @duplicate_kycs[u_k_d.user_id] ||= {
              GlobalConstant::UserKycDuplicationLog.active_status.to_sym => [],
              GlobalConstant::UserKycDuplicationLog.inactive_status.to_sym => []
          }

          @duplicate_kycs[u_k_d.user_id][GlobalConstant::UserKycDuplicationLog.active_status.to_sym] << GlobalConstant::UserEmailDuplicationLog.email_duplicate_type.humanize
          @duplicate_kycs[u_k_d.user_id][:id] = u_k_d.id
          @duplicate_kycs[u_k_d.user_id][:admin_status] = u_k_d.admin_status
          @duplicate_kycs[u_k_d.user_id][:cynopsis_status] = u_k_d.cynopsis_status
        end

      end

      # format duplicate data
      #
      # * Author: Aman
      # * Date: 07/05/2018
      # * Reviewed By:
      #
      def format_duplicate_data
        @duplicate_kycs.each do |_, kyc_data|
          kyc_data[GlobalConstant::UserKycDuplicationLog.active_status.to_sym] = kyc_data[GlobalConstant::UserKycDuplicationLog.active_status.to_sym].map {|x| x.humanize}
          kyc_data[GlobalConstant::UserKycDuplicationLog.inactive_status.to_sym] = kyc_data[GlobalConstant::UserKycDuplicationLog.inactive_status.to_sym].map {|x| x.humanize}
        end
      end

      # Set API response data
      #
      # * Author: Alpesh
      # * Date: 24/10/2017
      # * Reviewed By: sunil
      #
      # Sets @api_response_data
      #
      def set_api_response_data
        meta = {
            page_number: 1,
            page_payload: {
            }
        }

        @api_response_data = {
            meta: meta,
            result_set: 'user_duplicate_list',
            user_duplicate_list: @duplicate_kycs.values
        }
      end

    end

  end

end

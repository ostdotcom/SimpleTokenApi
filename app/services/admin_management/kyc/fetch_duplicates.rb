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
      # @params [Integer] case_id (mandatory) - user kyc details id
      #
      # @return [AdminManagement::Kyc::FetchDuplicates]
      #
      def initialize(params)
        super

        @admin_id = @params[:admin_id]
        @case_id = @params[:case_id]

        @duplicate_kycs = {}
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

        success_with_data(@duplicate_kycs)
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

        @user_kyc_detail = UserKycDetail.where(id: @case_id).first
        return error_with_data(
            'am_k_fd_1',
            'KYC detail id not found',
            '',
            GlobalConstant::ErrorAction.default,
            {}
        ) if @user_kyc_detail.blank?

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
        return if @user_kyc_detail.never_kyc_duplicate_status? || @user_kyc_detail.unprocessed_kyc_duplicate_status?

        duplicate_with_users = []

        duplicate_with_users += UserKycDuplicationLog.where(user1_id: @user_kyc_detail.user_id).order('status ASC, id DESC').all
        duplicate_with_users += UserKycDuplicationLog.where(user2_id: @user_kyc_detail.user_id).order('status ASC, id DESC').all
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

        UserKycDetail.where(user_id: @duplicate_kycs.keys).each do |u_k_d|
          @duplicate_kycs[u_k_d.user_id][:case_id] = u_k_d.id
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

        UserKycDetail.where(user_id: duplicate_email_user_ids).all.each do |u_k_d|
          @duplicate_kycs[u_k_d.user_id] ||= {
              GlobalConstant::UserKycDuplicationLog.active_status.to_sym => [],
              GlobalConstant::UserKycDuplicationLog.inactive_status.to_sym => []
          }

          @duplicate_kycs[u_k_d.user_id][GlobalConstant::UserKycDuplicationLog.active_status.to_sym] << 'Email'
          @duplicate_kycs[u_k_d.user_id][:case_id] = u_k_d.id
          @duplicate_kycs[u_k_d.user_id][:admin_status] = u_k_d.admin_status
          @duplicate_kycs[u_k_d.user_id][:cynopsis_status] = u_k_d.cynopsis_status
        end

      end

    end

  end

end
